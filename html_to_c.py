import os
from math import sqrt

HTML_FN = "../html/subtronics.txt"
C_FN = "/Users/grantfettig/totem/arduino/subtronics.c"

def main():
  
  
  #os.remove(C_FN)
  with open(HTML_FN, "r") as input_file:
    for line in input_file:
      pixel_info = line.split("#")
  color_hex = []
  for j in range(len(pixel_info)-1):
    color_hex.append(pixel_info[j+1].split(" ")[0])
    if(color_hex[j] == "000"):
      color_hex[j] = color_hex[j] + "000"
    if(color_hex[j] == "fff"):
      color_hex[j] = color_hex[j] + "fff"
  NUM_LEDS = len(color_hex)
  print "Number of pixels in html file: ", NUM_LEDS
  sorted_color_hex = []
  so_idx = 0
  for n in range(4): #for the 4 quadrants
    if(n==0): idx = 1023
    if(n==1): idx = 1023-16
    if(n==2): idx = 511-16
    if(n==3): idx = 511
    for k in range(16): # how many times down/back
      for m in range(16): #go down/back
        if(k%2==0): # go back
          sorted_color_hex.append(color_hex[idx-m])
        else: # go forwared
          sorted_color_hex.append(color_hex[idx+m])     
      if(k%2==0): idx = idx - 47
      else: idx = idx - 17 

  color_rgb = []
  for i in range(NUM_LEDS):
    r = int((sorted_color_hex[i][0] + sorted_color_hex[i][1]), 16)
    g = int((sorted_color_hex[i][2] + sorted_color_hex[i][3]), 16)
    b = int((sorted_color_hex[i][4] + sorted_color_hex[i][5]), 16)
    color_rgb.append("  LED.setPixelColor(" + str(i) + ", LED.Color(" + str(r) + ", " + str(g) + ", " + str(b) + "));") #the i needs to be different
  output_file = open(C_FN, "w")  
  output_file.write("#include <Adafruit_NeoPixel.h>" + '\n')
  output_file.write("#define LED_PIN 6" + '\n')
  output_file.write("#define LIGHT_COUNT 1024" + '\n')
  output_file.write("Adafruit_NeoPixel LED = Adafruit_NeoPixel(LIGHT_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);" + '\n')
  output_file.write("#define LED_PIN 6" + '\n')
  output_file.write('\n')
  output_file.write("void setup()" + '\n')
  output_file.write("{" + '\n')
  output_file.write("  LED.begin();" + '\n')
  output_file.write("}" + '\n')
  output_file.write('\n')
  output_file.write("void loop()" + '\n')
  output_file.write("{" + '\n')

  for n in range(len(color_rgb)):            
      output_file.write(color_rgb[n] + '\n')
  output_file.write("  LED.show();" + '\n')
  output_file.write("}")
main()