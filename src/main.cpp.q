#include "stdlib.h"   
#include "fstream"
#include "cv.h"
#include "highgui.h"
#include "iostream"
#include "highgui.h" 
#include "opencv2/opencv.hpp"   
#include "serial.h"
#include "MVCamera.h"
#include "MarkerSensor.h"
#include "Timer.h"
#include "pthread.h"
using namespace cv;
using namespace std;
//bool transmit_message = false;
#define WINDOW_NAME "追蹤"
unsigned char data_send_buf[8];

int H_max = 256;//126//223//103//1Debug35//131//101
int S_max = 256;//160//172//114//79//115//246
int V_max = 256;
int H_min = 0;//71//89//27//86//77//69
int S_min = 0;//8//4//16//29//13
int V_min = 180;//220//228//225//221//215//237
int a = 170;//176//192//200//168//124
int summ = 0;
int first = 1;
bool first_id=false;
double exp_time =6000;
bool large_resolution=true;
bool transmit_message = false;
//bool auto_exp = false;
int flag=0;//判断是否跟踪
int x = 0; int y = 0; int w_ = 640; int h_ = 480;

string dev = "/dev/ttyUSB0";
Serial sel((char *)dev.data());
unsigned char Add_CRC(unsigned char InputBytes[], unsigned char data_lenth)
{
	unsigned char byte_crc = 0;
	for (unsigned char i = 0; i < data_lenth; i++)
	{
		byte_crc += InputBytes[i];
	}
	return byte_crc;
}

void Data_disintegrate(unsigned int Data, unsigned char *LData, unsigned char *HData)
{
	*LData = Data & 0XFF;//0xFF = 1111 1111 
	*HData = (Data & 0xFF00) >> 8;//0xFF00 = 1111 1111 0000 0000
}

void Data_Code(unsigned int x_Data, unsigned int y_Data)
{
	int length = 8;
	data_send_buf[0] = 0xFF;
	data_send_buf[1] = length;
	data_send_buf[2] = 0x02;

	Data_disintegrate(x_Data, &data_send_buf[3], &data_send_buf[4]);
	Data_disintegrate(y_Data, &data_send_buf[5], &data_send_buf[6]);

	data_send_buf[length - 1] = Add_CRC(data_send_buf, length - 1);
}
void frame()
{
	//MV_camera
	//namedWindow(WINDOW_NAME, WINDOW_NORMAL);
	//namedWindow(src, WINDOW_NORMAL);
	//VideoCapture cap;
	Mat frame;//跟踪
	Mat tempImg;//原始
	int frame_num=0;
	double time_all=0;
	double time1 = 0, time2 = 0;
	vector<Rect>rect(20);
	vector<Rect>rect_(20);
	//yuan hsv
	int maxV = 0, minV = 0;
	int V = 0, S = 0, H = 0;
	int v = 0, s = 0, h = 0;
	int R = 0, G = 0, B = 0;
	int RR = 0, GG = 0, BB = 0;
	int RR_ = 0, GG_ = 0, BB_ = 0;
	int delta = 0, tmp = 0;
	int all = 0;
	//yuan zhizhen
	vector<vector<Point>>contours;
	uchar* whiteData;
	uchar* whiteData_;
	uchar* outData;
	uchar* rgbData;
	//int x_=0,y_=0;//上一个画面坐标记录
	
	MVCamera::Init();
	MVCamera::Play();
	//MVCamera::SetExposureTime(false, 1000);
	MVCamera::SetExposureTime(false, exp_time);
	MVCamera::SetLargeResolution(false);
	
 	//MVCamera::GetFrame(frame);
	//if (frame.empty())//Èç¹ûÊÓÆµ²»ÄÜÕý³£Žò¿ªÔò·µ»Ø
	//{
	//	cout << "视频打开失败" << endl;
	//	return -1;
	//}
	//MVCamera::SetLargeResolution(false);
	while (true)
	{
		MVCamera::GetFrame(tempImg);
		    if (tempImg.empty()) {
		      printf("Image empty !\n");
		      continue;
		    }
		frame_num++;
		//resize(tempImg, tempImg, Size(640,480), INTER_LINEAR);
		//MVCamera::SetLargeResolution(true);
		//cap >> frame;//µÈŒÛÓÚcap.read(frame);
		//if (tempImg.empty())//Èç¹ûÄ³Ö¡Îª¿ÕÔòÍË³öÑ­»·
		//	break;
		//MVCamera::SetExposureTime(auto_exp, exp_time);
		//imshow("video", frame);
		if (first)
		{
			//resize(tempImg, tempImg, Size(640,480), INTER_LINEAR);
			frame = tempImg;
			 x = 0; y = 0; w_ = 640; h_ = 480;
			// x_=0;y_=0;
			//cout<<"first"<<endl;
		}
		else
		{
			if (x < 0) x = 0;
			if (y < 0) y = 0;
			if ((x + w_) > 640) w_ = 640 - x;
			if ((y + h_) > 480) h_ = 480 - y;
			frame = tempImg(Rect(x, y, w_, h_));
		}

		int iheight = frame.rows;
		int jwidth = frame.cols;
		cv::Mat dstImage = Mat::zeros(iheight, jwidth, CV_8U);//二值跟踪

		//yuan   hsv
		
		
		//int max_ = 0, min_ = 0;
		//Mat element = getStructuringElement(MORPH_RECT, Size(5, 5));
	//	morphologyEx(frame, frame, MORPH_OPEN, element, Point(-1, -1), 2);
		/*clock_t start, finish;
		double totaltime;
		start = clock();*/

		//
		//Size ResImgSiz = Size(jwidth-20,iheight-20);
		//cv::Mat ResImg = Mat(ResImgSiz, dstImage.type());
		
		//yuan zhizhen
		int width = 0;
		int height = 0;
		//int x, y;
		int kk, tt;

		time1 = getTickCount();
		//cout<<"h,w"<<iheight<<","<<jwidth<<endl;
		for (int i = 0; i < iheight; i++)
		{
			//int i = 0,j = 75;
			//const uchar* inData = dstImage.ptr<uchar>(i);
			 outData = dstImage.ptr<uchar>(i);
			 rgbData = frame.ptr<uchar>(i);
			for (int j = 0; j < jwidth; j++)
			{
				//Point p(i, j);

				//rgb>>hsv
				R = rgbData[3 * j];//ÏàÓŠÎ»ÖÃµÄRÖµ
				G = rgbData[3 * j + 1];//ÏàÓŠÎ»ÖÃµÄGÖµ
				B = rgbData[3 * j + 2];//ÏàÓŠÎ»ÖÃµÄBÖµ

				tmp = min(R, G);
				minV = min(tmp, B);
				tmp = max(R, G);
				maxV = max(tmp, B);
				all = (maxV + minV) ;//consider to delete!!!!!!!!!!!!!!!!!!!!!!!
				v = maxV ; // v			
				delta = maxV - minV;
				if (maxV != 0)
					s = delta  / maxV; // s			
				else
				{
					s = 0;
				}
				if (delta == 0)
					H = 0;
				else if (R == maxV)
					H = (G - B) / delta;
				else if (G == maxV)
					H = 2 + (B - R) / delta;
				else
					H = 4 + (R - G) / delta;
				H *= 60;
				if (H < 0)
					H += 360;
				h = H / 2;
				//s = S * 255.0;
				//v = V * 255.0;
				//cvSet2D(frame, i, j, st);       //set the (i,j) pixel value
				//ÅÐ¶Ï
				/*if ()
					outData[j] = 255;*/
					//cout << "all:" << all << " h:" << h << " s:" << s << " v:" << v << " sumRGB:" << sumRGB << endl;
				if ((all >= a) && (h <= H_max) && (h >= H_min) && (s <= S_max) && (s >= S_min) && (v <= V_max) && (v >= V_min))
					outData[j] = 255;
				//imshow(WINDOW_NAME, dstImage);
				//cout << i << "," << j << int(outData[j])<<endl;
				//waitKey(5);
			}
		}
		/*Mat element = getStructuringElement(MORPH_RECT, Size(5, 5));

		morphologyEx(dstImage, dstImage, MORPH_ERODE, element, Point(-1, -1), 2);

		morphologyEx(dstImage, dstImage, MORPH_DILATE, element, Point(-1, -1), 4);*/
		/*Size ResImgSiz = Size(620, 460);
		Mat ResImg = Mat(ResImgSiz, dstImage.type());*/

		//resize(dstImage, ResImg, ResImgSiz, INTER_LINEAR);
		//1ResImg=dstImage(Rect(10,10,jwidth-10,iheight-10));
		//vector<vector<Point>>contours;

		findContours(dstImage, contours, RETR_EXTERNAL, CHAIN_APPROX_NONE);
		int number_rect = 0;

		for (int k = 0; k < contours.size(); k++)
		{

			rect[k] = boundingRect(contours[k]);
			//x = rect[k].x;
			//y = rect[k].y;
			width = rect[k].width;
			height = rect[k].height;
			//uchar* rgbData_ = frame.ptr<uchar>((int)(x + width / 2));
			if (((height / width) > 1.8) && ((height*width) < 10000&& (height*width) > 50))//
			{
				//	cout << "R:" << (int)(rgbData_[3 * ((int)(y + height / 2))]) << "\n";
				rectangle(frame, Point(rect[k].x , rect[k].y ), Point(rect[k].x + width , rect[k].y + height ), Scalar(0, 255, 0), 2);
				//*(xx + number_rect) = x;
				//*(yy + number_rect) = y;
				rect_[number_rect++] = rect[k];


			}
			else
				first = 1;
			//int* white = new int[number_rect];
			//float* propotion = new float[number_rect];
			//for (int h = 0; h < number_rect; h++)
			//{
			//	for (int i = 0; i < rect[h].height; i++)
			//	{
			//		uchar* whiteData = frame.ptr<uchar>(rect[h].x);
			//		for (int j = 0; j < rect[h].width; j++)
			//		{
			//			if (whiteData[j] == 255)
			//				white[h]++;
			//			propotion[h] = white[i] * 1.0 / (rect[h].width*rect[h].height);
			//			cout << "rect[" << i << "]" << propotion[h] << "\n";
			//		}
			//	}
			//}
		}
		
		//cout<<"number_rect:"<<number_rect<<endl;
		flag=0;
		//判断装甲板
		
		for (int i = 0; i < number_rect; i++)
		{
			for (int j = i + 1; j < number_rect; j++)
			{
				whiteData = frame.ptr<uchar>((int)(rect_[i].y+0.3*rect_[i].height));
				whiteData_ = frame.ptr<uchar>((int)(rect_[i].y+0.6*rect_[i].height));
				int numm = 0;
				//int numm_=0;
				
				////if(rect_[i].x< rect_[j].x)
				kk = min(rect_[i].x, rect_[j].x);
				tt = kk;
				//cout << "abs(rect_[i].x - rect_[j].x):" << abs(rect_[i].x - rect_[j].x) << endl;
				for (; kk < (tt+abs(rect_[i].x - rect_[j].x));kk++)
				{
						RR = whiteData[3 * kk];//ÏàÓŠÎ»ÖÃµÄRÖµ
						GG = whiteData[3 * kk + 1];//ÏàÓŠÎ»ÖÃµÄGÖµ
						BB = whiteData[3 * kk + 2];//ÏàÓŠÎ»ÖÃµÄBÖµ
						RR_ = whiteData_[3 * kk];//ÏàÓŠÎ»ÖÃµÄRÖµ
						GG_ = whiteData_[3 * kk + 1];//ÏàÓŠÎ»ÖÃµÄGÖµ
						BB_ = whiteData_[3 * kk + 2];//ÏàÓŠÎ»ÖÃµÄBÖµ
				//		tmp = min(RR, GG);
				//		minV = min(tmp, BB);
				//		tmp = max(RR, GG);
				//		maxV = max(tmp, BB);
				//		//all = (maxV + minV) * 255;
				//		v = maxV * 255.0; // v			
				//		delta = maxV - minV;
				//	if (maxV != 0)
				//		s = delta * 255.0 / maxV; // s			
				//	else
				//	{
				//		s = 0;
				//	}
				//	if (delta == 0)
				//		H = 0;
				//	else if (RR == maxV)
				//		H = (GG - BB) / delta;
				//	else if (GG == maxV)
				//		H = 2 + (BB - RR) / delta;
				//	else
				//		H = 4 + (RR - GG) / delta;
				//	H *= 60;
				//	if (H < 0)
				//		H += 360;
				//	h = H / 2;
				//	cout << h << endl;
				//	if ((h < 256)&&(h!=0))
					if((RR>50)&&(GG>50)&&(BB>50)&&(RR_>50)&&(GG_>50)&&(BB_>50))
						numm++;
				}

				//printf("numm:%d\n", numm);
				if (numm > 6)
				{
					if (2.8*min(rect_[i].height, rect_[i].height) > abs(rect_[i].x - rect_[j].x))
					{
						if (abs(rect_[i].y - rect_[j].y) < height)
						{
							first = 0;
							//cout<<"1"<<endl;
							if (rect_[i].x < rect_[j].x)
							{
								
								//if(((*yy+height)>*(yy+1))&&((*(yy + 1)+ height) > *yy))
								rectangle(tempImg, Point(rect_[i].x+x , rect_[i].y+y ), Point(rect_[j].x+x + rect_[j].width, rect_[j].y+y + rect_[j].height ),Scalar(255, 0, 0), 2);
								//x_=x;y_=y;
								x = rect_[i].x+x  - 40;
								y = rect_[i].y+y  - 40;
								w_ = rect_[j].x+ rect_[j].width-rect_[i].x+80;//150待定
								h_ = rect_[j].y+ rect_[j].height-rect_[i].y+80;
								//cout<<"dkk"<<endl;
								transmit_message = 1;
								flag=1;break;

							}
							else
							{
								
								//if (((*yy + height) < *(yy + 1)) && ((*(yy+1) + height) > *yy))
								rectangle(tempImg, Point(rect_[j].x+x, rect_[j].y+y ), Point(rect_[i].x+x + rect_[i].width , rect_[i].y+y + rect_[i].height ),Scalar(255, 0, 0), 2);
								//x_=x;y_=y;
								x = rect_[j].x+x - 40;
								y = rect_[j].y+y - 40;
								w_ = rect_[i].x+ rect_[i].width-rect_[j].x+80;
								h_ = rect_[i].y+ rect_[i].height-rect_[j].y+80;
								transmit_message = 1;
								flag=1;break;
							}
						}
						else
						{
							first = 1;flag=0;
							transmit_message = 0;
						}
					}
					else
					{
						first = 1;flag=0;
						transmit_message = 0;
					}
				}
				else
				{
					first = 1;
					transmit_message = 0;
				}

			}
			if(flag==1) break;
		}//判断装甲板
		if(flag==0) first=1;
		time1 = getTickCount()-time1;
		//float time_ = (time2 - time1) / cvGetTickFrequency();
		//cout << "time_" << time_ / 1000 << endl;
		/*finish = clock();
		totaltime = (double)(finish - start) / CLOCKS_PER_SEC;&&(>100)
		cout << "\nŽË³ÌÐòµÄÔËÐÐÊ±ŒäÎª" << totaltime << "Ãë" << endl;*/
		//time1*=0.6;
		//timetime
		//cout<<"cvGetTickFrequency:"<<cvGetTickFrequency<<endl;
		//cout<<time_all<<endl;
		time_all=time_all+time1;
		
		char key=waitKey(1);
		if(key==27||key=='q'||key=='Q'){
			break;
		}
		if(key=='z'||key=='Z'){
			system("pause");
		}
		if(key=='p'||key=='P'){
			exp_time+=500;
			MVCamera::SetExposureTime(false, exp_time);
			cout<<"exp_time:"<<exp_time<<endl;
		}
		if(key=='m'||key=='M'){
			if(exp_time-1000>0)
				exp_time-=500;
			MVCamera::SetExposureTime(false, exp_time);
			cout<<"exp_time:"<<exp_time<<endl;
		}
		if(key=='b'||key=='B'){
			large_resolution=!large_resolution;
			MVCamera::SetLargeResolution(large_resolution);
		}
		cv::imshow("track", frame);
		
		
		//morphologyEx(dstImage, dstImage, MORPH_OPEN, element, Point(-1, -1), 2);
		//morphologyEx(dstImage, dstImage, MORPH_ERODE, element, Point(-1, -1), 1);
		//morphologyEx(dstImage, dstImage, MORPH_DILATE, element, Point(-1, -1), 4);
		cv::imshow("src", tempImg);
		//imshow("stc", MarkSensor::img_show);	
		cv::imshow("dst", dstImage);
		waitKey(10);//Ã¿Ö¡ÑÓÊ±20ºÁÃë
	}
	//cap.release();//ÊÍ·Å×ÊÔŽ
	time_all=time_all/1000000/(double)(cvGetTickFrequency());
	double fps=(double)(frame_num)/time_all;
	cout<<"fps:"<<fps<<endl;
	destroyAllWindows();
	MVCamera::Stop();
	MVCamera::Uninit();
}
void serial()
{
	
	//sel.setPara();
	while(true)
	{
		if ((transmit_message == 1)&&(x+y!=0))
		{

			char buff[8];
			//x=400;y=300;
			//int width=20;int height=15;//15
			int X_bias = x+w_/2;
			int Y_bias = y+h_/2;
			cout << "X:" << X_bias << "," << "Y:" << Y_bias << endl;
			//messnum++;
			Data_Code(X_bias, Y_bias);
			for (int i = 0; i < 8; i++)
				buff[i] = data_send_buf[i];
			sel.writeData(buff, 8);
		}
		else //if (transmit_message == 0)
		{
			char buff[8];
			Data_Code(850, 850);
			for (int i = 0; i < 8; i++)
				buff[i] = data_send_buf[i];
			sel.writeData(buff, 8);
		}
	}
}
	

int main()
{
	//pthread_t tid1;
	//pthread_t tid2;
	//pthread_create(&tid1,frame);
	//pthread_create(&tid2,serial);
	//pthread_join(tid1);
	//pthread_join(tid2);
	//getchar();
	sel.setPara();
	thread th1(&frame);
	thread th2(&serial);
	th2.join();
	th1.join();
	return 0;

}
