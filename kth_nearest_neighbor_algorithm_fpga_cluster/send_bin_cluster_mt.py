import socket
import struct
import time
import math
import threading

#---GLOBAL VARIABLES---

#---User initialiazations---
file_name="bin_file.bin"
k=4
num_zybos=1
tot_num_train=100
dim_ints=10000
pkt_size_ints=320

#---Other variables needed---
train_vectors_per_board=int(tot_num_train/num_zybos)
pkts_per_vector=math.ceil(dim_ints/pkt_size_ints)
last_pkt_size=int(((dim_ints/pkt_size_ints)%1)*pkt_size_ints)
pkts_per_board=int(pkts_per_vector*(train_vectors_per_board+1))
snd_pkt_size_bytes=int(pkt_size_ints*4)
last_pkt_size_bytes=int(last_pkt_size*4)
rec_pkt_size_bytes=int(k*4)
dim_bytes=int(dim_ints*4)
#---Client sockets---
TCP_IP1 = '192.168.1.11'
TCP_PORT1=5
TCP_IP2 = '192.168.1.12'
TCP_PORT2=11
TCP_IP3 = '192.168.1.13'
TCP_PORT3=13
TCP_IP4 = '192.168.1.14'
TCP_PORT4=17
#---Offsets so every 3rd vector is sent to a board
offset1=0
offset2=1
offset3=2
offset4=3
#---Print individual boards kth nearest and overall kth nearest
kth_nearest=[]
#---Print parameters to make sure they match with Zybos---
print("K: ", k)
print("Number of Zybos: ", num_zybos)
print("Total Train Vectors: ", tot_num_train)
print("Number of Dimensions for each Vector: ", dim_ints)
print("Ethernet Packet Size in Integers: ", pkt_size_ints)
print("Number of Packets For Each Vector", pkts_per_vector)
print("Number of Train Vectors Each Board Will Receive: ",train_vectors_per_board)
print("Number of Packets Each Board Will be sent: ", pkts_per_board)



def run_program():
    #---Receives the individual boards kth nearest---
    kth_nearest1=[]
    kth_nearest2=[]
    kth_nearest3=[]
    kth_nearest4=[]
    start_time = time.clock()

    #---Threads to send packets and receive packets
    if num_zybos>0:
        print("creating thread 1")
        t1=threading.Thread(target=client_socket, args=(TCP_IP1, TCP_PORT1, offset1, kth_nearest1))
    if num_zybos>1:
        print("creating thread 2")
        t2=threading.Thread(target=client_socket, args=(TCP_IP2, TCP_PORT2, offset2, kth_nearest2)) 
    if num_zybos>2:
        print("creating thread 3")
        t3=threading.Thread(target=client_socket, args=(TCP_IP3, TCP_PORT3, offset3, kth_nearest3))
    if num_zybos>3:
        print("creating thread 4")
        t4=threading.Thread(target=client_socket, args=(TCP_IP4, TCP_PORT4, offset4, kth_nearest4))
        
    if num_zybos>0:
        t1.start()
    if num_zybos>1:
        t2.start()
    if num_zybos>2:
        t3.start()
    if num_zybos>3:
        t4.start()
    if num_zybos>0:
        t1.join()
    if num_zybos>1:
        t2.join()
    if num_zybos>2:
        t3.join()
    if num_zybos>3:
        t4.join()
        
    if num_zybos==1:
        kth_nearest=kth_nearest1
    if num_zybos==2:
        kth_nearest=sorted(kth_nearest1+kth_nearest2)
    if num_zybos==3:
        kth_nearest=sorted(kth_nearest1+kth_nearest2+kth_nearest3)
    if num_zybos==4:
        kth_nearest=sorted(kth_nearest1+kth_nearest2+kth_nearest3+kth_nearest4)

    print("\n---Results---")
    for x in range(0, k):
        print(x, "th nearest: ", kth_nearest[x])    
    end_time = time.clock()
    print("Total Time:",(end_time-start_time))

def client_socket(TCP_IP, TCP_PORT, thread_offset, kth_nearest):
    #---Open binary file---
    file = open(file_name, "rb")
    #---Connect to client sockets---
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_socket.connect((TCP_IP, TCP_PORT))
    print("Connected to ", TCP_IP)
    #---Read file and send test vector---
    for i in range(0, pkts_per_vector):
        if i == pkts_per_vector-1:
            payload = file.read(last_pkt_size_bytes)
        else:
            payload = file.read(snd_pkt_size_bytes)
        client_socket.send(payload)
        time.sleep(1/10000000)
    #send the train vectors
    for i in range(0, train_vectors_per_board):
        file.seek(dim_bytes+i*num_zybos*dim_bytes+thread_offset*dim_bytes)
        for j in range(0, pkts_per_vector):  
            if j == pkts_per_vector-1:
                payload = file.read(last_pkt_size_bytes)
            else:
                payload = file.read(snd_pkt_size_bytes)
            client_socket.send(payload)
            time.sleep(1/10000000)
    print("Done sending to ", TCP_IP)
    file.close()
    #---Receive packets---
    recpacket = client_socket.recv(rec_pkt_size_bytes)
    print("Received packet from ", TCP_IP)
    i=0
    j=3
    for x in range(0, k):
        kth_nearest.append(int.from_bytes(recpacket[i:j], byteorder='little'))
        i=i+4
        j=j+4
        
run_program()




