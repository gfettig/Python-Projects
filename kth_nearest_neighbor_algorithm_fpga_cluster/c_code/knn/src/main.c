#include "dma.h"
#include "ethernet.h"
void merge(int * arr, int l, int m, int r);
void mergeSort(int * arr, int l, int r);

int main(void){
	printf("\r\n--- Entering main() --- \r\n");


	/*---User initializations*/
	int k = 4;
	int num_zybos=1;
	int tot_num_train = 100;
	int dim_ints = 10000;
	int pkt_size_ints=320;

	/*---Choose which IP address, port, and mac address to make this board*/
	int Zybo = 1;
	mac_ethernet_address=malloc(6);
	if(Zybo==1){
		IP=11;
		port=5;
		mac_ethernet_address[5]=0x02;
	}
	else if(Zybo==2){
		IP=12;
		port=11;
		mac_ethernet_address[5]=0x03;
	}
	else if(Zybo==3){
		IP=13;
		port=13;
		mac_ethernet_address[5]=0x04;
	}
	else{
		IP=14;
		port=17;
		mac_ethernet_address[5]=0x05;
	}

	/*Other Variables Needed*/
	int num_train=tot_num_train/num_zybos;
	int * kth_nearest = malloc(sizeof(int)*k);
	//to do ceil without function
	int remainder=(dim_ints/pkt_size_ints)%1;
	int pkts_per_vector=dim_ints/pkt_size_ints-remainder+1;
	NUM_ETH_PACKETS = pkts_per_vector*(num_train+1);
	ETH_PACKETS_RECEIVED=0;
	BUF_OFFSET=0;
	VECTORS=malloc(sizeof(int)*(num_train+1)*dim_ints);
	int dma_packet_buffer_size=sizeof(int)*dim_ints*2;
	int * dma_packet_buffer  = malloc(dma_packet_buffer_size);
	int * distances = malloc(sizeof(int)*num_train);
	int i, j;

	/*---Print parameters to make sure they match the python script---*/
	printf("K: %i\n",k);
	printf("Number of Zybos: %i\n",num_zybos);
	printf("Total Train Vectors: %i\n", tot_num_train);
	printf("Number of Dimensions For Each Vector: %i\n",dim_ints);
	printf("Ethernet Packet Size in Integers: %i\n",pkt_size_ints);
	printf("Number of Packets For Each Vector: %i\n", pkts_per_vector);
	printf("Number of Train Vectors Each Board Will Receive: %i\n",num_train);
	printf("Number of Packets Each Board Will Be Sent: %i\n", NUM_ETH_PACKETS);


	/*set ip address and ip address that it can accept*/
	ethernet_config();
	/*wait to accept*/
	ethernet_accept();
	/*receive ethernet packets*/
	ethernet_receive();

	/*
	for(i=0; i<num_train; i++){
		for(j=0;j<dim_ints;j++){
			if(*((int*)(VECTORS)+j)>20 || *((int*)(VECTORS)+j)<-20) printf("test[%i] is wrong: %i\n", j, *((int*)(VECTORS)+j));
			if(*((int*)(VECTORS)+dim_ints+dim_ints*i+j)>20 || *((int*)(VECTORS)+dim_ints+dim_ints*i+j)<-20) printf("train[%i] is wrong: %i\n", j, *((int*)(VECTORS)+dim_ints+dim_ints*i+j));
		}
	}*/
	PACKET_SIZE_REG = dim_ints*2;
	TRAIN_VECTORS = num_train;
	RESET = 0xFFFFFFFF;
	RESET = 0x00000000;
	printf("Calculating Distances with FPGA...\n");
	u8 *packet = (u8*)dma_packet_buffer;
	int m;
	m=0;
	for(j=0;j<dim_ints;j++){
		dma_packet_buffer[m]=*((int*)(VECTORS)+j);
		m=m+2;
	}

	for(i=0; i<num_train; i++){
		m=0;
		for(j=0;j<dim_ints;j++){
			dma_packet_buffer[m+1]=*((int*)(VECTORS)+dim_ints+dim_ints*i+j);
			//if(dma_packet_buffer[m+1]!= i*dim_ints+j+dim_ints) printf("train[%i]: %i\n", i*dim_ints+j,dma_packet_buffer[m+1]);
			m=m+2;
		}
		init_dma2();
		printf("%d:\t\t%d\t%d\t%d\t%d\n", i, INT2, INT1, INT4, INT3);
		SendPacket((packet), dma_packet_buffer_size);
	}
	printf("\n");
	free(dma_packet_buffer);
	printf("Calculating Distances with Processor...\n");
		for(i=0; i<num_train; i++){
			distances[i]=0;
			for(j=0;j<dim_ints;j++){
				distances[i]=distances[i]+((*((int*)(VECTORS)+j)-*((int*)(VECTORS)+dim_ints+dim_ints*i+j))*(*((int*)(VECTORS)+j)-*((int*)(VECTORS)+dim_ints+dim_ints*i+j)));
			}
		}
		mergeSort(distances, 0, num_train-1);

	free(VECTORS);
	while(!DONE);
	printf("\nDone calculating distances with FPGA\n");

	printf("\n--- This boards results: ---\n");
	if(k>0){
		printf("1st nearest: %i\n",INT1);
		kth_nearest[0]=INT1;
	}
	if(k>1){
		printf("2nd nearest: %i\n",INT2);
		kth_nearest[1]=INT2;
	}
	if(k>2){
		printf("3rd nearest: %i\n",INT3);
		kth_nearest[2]=INT3;
	}
	if(k>3){
		printf("4th nearest: %i\n\n",INT4);
		kth_nearest[3]=INT4;
	}
	RESET = 0xFFFFFFFF;
	printf("\nDone calculating distances with Processor\n\n");
	for(i=0;i<k;i++) printf("k nearest %i from processor: %i\n",i,distances[i]);
	/*send data back to the PC*/
	ethernet_send(kth_nearest, k);
	xil_printf("\n--- Exiting main() --- \r\n");
	return 0;
}

void mergeSort(int * arr, int l, int r){
	if (l < r){
		int m = l+(r-l)/2;
		mergeSort(arr, l, m);
		mergeSort(arr, m+1, r);
		merge(arr, l, m, r);
	}
}

void merge(int arr[], int l, int m, int r){
	int i, j, k;
	int n1 = m - l + 1;
	int n2 =  r - m;
	int L[n1], R[n2];

	for (i = 0; i < n1; i++) L[i] = arr[l + i];
	for (j = 0; j < n2; j++) R[j] = arr[m + 1+ j];

	i = 0;
	j = 0;
	k = l;
	while (i < n1 && j < n2){
		if (L[i] <= R[j]){
			arr[k] = L[i];
			i++;
		}
		else{
			arr[k] = R[j];
			j++;
		}
		k++;
	}

	while (i < n1){
		arr[k] = L[i];
		i++;
		k++;
	}

	while (j < n2){
		arr[k] = R[j];
		j++;
		k++;
	}
}
