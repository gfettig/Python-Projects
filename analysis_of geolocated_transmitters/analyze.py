import os
import csv
import math
import matplotlib.pyplot as plt

def main(): 
  data = read_file()
  enbids = enbid_info(data) #collect data related to eNB IDs
  
  #avg_dist(enbids) #find distances between eNB IDs
  #cf_sec_cross(data) #cross references center freq & sector ID no coorlation..?
  #dist_cf(enbids) #no coorilation 
  #dist_antennas(enbids) #no coorilation
  #dist_cf(data) #no coorilation
  #dist_pci(enbids) #no coorilation, after learning what PCI is wouldn't make sense
  #loc_pattern(enbids) #there is a grouping
  #bandwidth_pci(enbids) #no coorilation
  #band_earfcn(data) #each earfcn has a unitque bandwidtch

  
def read_file():
  data = list(csv.reader(open('geolocated_transmitters.csv')))
  for i in range(len(data[0])):
    print i, ':', data[0][i]
  return data

def enbid_info(data):
  total = 0
  enbIds=[]
  longitude=[]
  latitude=[]
  cf=[]
  sf=[]
  ef=[]
  sId=[]
  antennas=[]
  earfcn=[] #directly coorliated with bandwidth and band
  mcc=[]
  mnc=[]
  bandwidth=[]
  standard=[]
  tac=[]
  band=[]
  pci=[]
  towers=[]
  #store info for each unique tower location
  for i in range(1 ,len(data)):
    if data[i][1] not in enbIds: 
      total = total + 1
      enbIds.append(data[i][1])
      cf.append(float(data[i][3]))
      sf.append(float(data[i][4]))
      ef.append(float(data[i][5]))
      sId.append(float(data[i][6]))
      longitude.append(float(data[i][7]))
      latitude.append(float(data[i][8]))
      antennas.append(float(data[i][9]))
      earfcn.append(float(data[i][10]))
      mcc.append(float(data[i][11]))
      mnc.append(float(data[i][12]))
      bandwidth.append(float(data[i][13]))
      standard.append(data[i][14])
      tac.append(float(data[i][15]))
      band.append(data[i][17])
      pci.append(float(data[i][18]))
  towers.append(enbIds)#0
  towers.append(longitude)#1
  towers.append(latitude)#2
  towers.append(cf)#3
  towers.append(sf)#4
  towers.append(ef)#5
  towers.append(sId)#6
  towers.append(antennas)#7
  towers.append(earfcn)#8
  towers.append(mcc)#9
  towers.append(mnc)#10
  towers.append(bandwidth)#11
  towers.append(standard)#12
  towers.append(tac)#13
  towers.append(band)#14
  towers.append(pci)#15
  return towers

class Cf_SecID_Cross():
  def __init__(self, cf, sids):
    self.cf = cf
    self.sids = sids
    self.longitude = []
    self.latitude = []

def cf_sec_cross(data):
  cfs = []
  sids = []
  cfSidCross = []
  for i in range(1 ,len(data)):
    if(float(data[i][3]) not in cfs):
      cfs.append(float(data[i][3]))
    if(float(data[i][6]) not in sids):
      sids.append(float(data[i][6]))
  #print cfs
  print sids
  for j in range(1 ,len(data)):
    for k in range(0 ,len(cfs)): #find which cf
      if float(data[j][3]) == cfs[k]:
        for m in range(0, len(sids)): #find which sids
          if (float(data[j][6]) == sids[m]):
            combExist = 0
            for n in range(0, len(cfSidCross)):
              if cfSidCross[n].cf == cfs[k] and cfSidCross[n].sids == sids[m]:
                cfSidCross[n].longitude.append(data[j][8])
                cfSidCross[n].latitude.append(data[j][7])
                combExist = 1
            if combExist == 0:
              cfSidCross.append(Cf_SecID_Cross(cfs[k], sids[m]))
              cfSidCross[len(cfSidCross)-1].longitude.append(data[j][8])
              cfSidCross[len(cfSidCross)-1].latitude.append(data[j][7])

  distances = []
  means = []
  cfsplot = []
  sidsplot = []
  for j in range(0 ,len(cfSidCross)): #go through cfSidCross
    for k in range(0, len(cfSidCross[j].longitude)): 
      for m in range(0, len(cfSidCross[j].longitude)):
        if(k != m): 
          temp_dist=math.sqrt(((float(cfSidCross[j].longitude[k])-float(cfSidCross[j].longitude[m]))**2)+((float(cfSidCross[j].latitude[k])-float(cfSidCross[j].latitude[m]))**2))
          distances.append(temp_dist)  
    total=sum(distances)
    means.append(total/len(distances))
    cfsplot.append(cfSidCross[j].cf)
    sidsplot.append(cfSidCross[j].sids)
    del distances [:]
  plt.scatter(means, cfsplot)
  plt.xlabel('Average Distance')
  plt.ylabel('Center Frequencies(MHz)')
  plt.title('Average Distance vs Center Frequencies for Inidiviual Sectors')
  plt.show()

#What are the typical distances between transmitters?
def avg_dist(towers):
  distance=[]
  #calculate distances from each tower
  for j in range(0, len(towers[0])): 
    for k in range(0, len(towers[0])):
      temp_dist=math.sqrt(((towers[1][j]-towers[1][k])**2)+((towers[2][j]-towers[2][k])**2))
      if(j != k): 
        distance.append(temp_dist)  
  total=sum(distance)

  mean=total/len(distance)
  s = sorted(distance)
  median = s[len(distance)/2]
  print "Mean Distance Between Transmitters:", mean
  print "Median Distance Between Transmitters:", median

def dist_cf(towers):
  distance=[]
  comb_cf=[]
  for j in range(0, len(towers[0])): 
    for k in range(0, len(towers[0])):
      temp_dist=math.sqrt(((towers[1][j]-towers[1][k])**2)+((towers[2][j]-towers[2][k])**2))
      temp_comb_cf=towers[3][j]+towers[3][k]
      if(temp_dist not in distance and j != k): 
        distance.append(temp_dist)
        comb_cf.append(temp_comb_cf)
  plt.scatter(comb_cf, distance)
  plt.show()

def dist_antennas(towers):
  distance=[]
  comb_antennas=[]
  for j in range(0, len(towers[0])): 
    for k in range(0, len(towers[0])):
      temp_dist=math.sqrt(((towers[1][j]-towers[1][k])**2)+((towers[2][j]-towers[2][k])**2))
      temp_comb_antennas=towers[7][j]+towers[7][k]
      if(temp_dist not in distance and j != k): 
        distance.append(temp_dist)
        comb_antennas.append(temp_comb_antennas)
  plt.scatter(comb_antennas, distance)
  plt.show()

class DistCf_Cross():
  def __init__(self, cf):
    self.cf = cf
    self.longitude = []
    self.latitude = []
    self.avg_dist = 0

def dist_cf(data):
  cfs = []
  distCfCross = []
  for i in range(1 ,len(data)): #get list of center frequencies
    if(float(data[i][3]) not in cfs):
      distCfCross.append(DistCf_Cross(data[i][3]))

  for j in range(1, len(data)): #put cf longitudes and latitudes into respected groups
      for k in range(0, len(distCfCross)):
        if(distCfCross[k].cf == data[j][3]):
          distCfCross[k].latitude.append(data[j][7])
          distCfCross[k].longitude.append(data[j][8])
  for m in range(0, len(distCfCross)):
    temp_tot_dist = 0
    for n in range(0, len(distCfCross[m].longitude)):
      for p in range(0, len(distCfCross[m].longitude)):
        if(n != p):
          temp_dist = math.sqrt(((float(distCfCross[m].longitude[n])-float(distCfCross[m].longitude[p]))**2)+((float(distCfCross[m].latitude[n])-float(distCfCross[m].latitude[p]))**2))
          temp_tot_dist = temp_tot_dist + temp_dist 
    distCfCross[m].avg_dist = temp_tot_dist/len(distCfCross[m].longitude)
  cfsPlot = []
  distPlot = []
  for r in range(0, len(distCfCross)):
    cfsPlot.append(distCfCross[r].cf)
    distPlot.append(distCfCross[r].avg_dist)

  plt.scatter(cfsPlot, distPlot)
  plt.show()




#What are the typical distances between transmitters?
def avg_dist(towers):
  distance=[]
  #calculate distances from each tower
  for j in range(0, len(towers[0])): 
    for k in range(0, len(towers[0])):
      temp_dist=math.sqrt(((towers[1][j]-towers[1][k])**2)+((towers[2][j]-towers[2][k])**2))
      if(j != k): 
        distance.append(temp_dist)  
  total=sum(distance)

  mean=total/len(distance)
  s = sorted(distance)
  median = s[len(distance)/2]
  print "Mean Distance Between Transmitters:", mean
  print "Median Distance Between Transmitters:", median
  plt.scatter(comb_band, distance)
  plt.show()

def dist_pci(towers): 
  distance=[]
  comb_pci=[]
  for j in range(0, len(towers[0])): 
    for k in range(0, len(towers[0])):
      temp_dist=math.sqrt(((towers[1][j]-towers[1][k])**2)+((towers[2][j]-towers[2][k])**2))
      temp_comb_pci=towers[15][j]+towers[15][k]
      if(temp_dist not in distance and j != k): 
        distance.append(temp_dist)
        comb_pci.append(temp_comb_pci)
  plt.scatter(comb_pci, distance)
  plt.show()

def loc_pattern(towers):
  plt.scatter(towers[1], towers[2])
  plt.show() 

def bandwidth_pci(towers):
  comb_bandwidth=[]
  comb_pci=[]
  distance=[]
  for j in range(0, len(towers[0])): 
    for k in range(0, len(towers[0])):
      temp_dist=math.sqrt(((towers[1][j]-towers[1][k])**2)+((towers[2][j]-towers[2][k])**2))
      temp_comb_pci=towers[15][j]+towers[15][k]
      temp_comb_bandwidth=towers[11][j]+towers[11][k]
      if(temp_dist not in distance and j != k): 
        distance.append(temp_dist)
        comb_pci.append(temp_comb_pci)
        comb_bandwidth.append(temp_comb_bandwidth)
  plt.scatter(comb_pci, comb_bandwidth)
  plt.show()

#earfcn is directly coorilated
def band_earfcn(data):
  earfcn = []
  band = []
  for i in range(1 ,len(data)):
    earfcn.append(data[i][10])
    band.append(data[i][13])
  plt.scatter(band, earfcn)
  plt.xlabel('Bandwidth')
  plt.ylabel('EARFCN')
  plt.title('Bandwidth with Unique EARFCN')
  
  plt.show()

main()