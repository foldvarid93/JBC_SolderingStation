/*
 * Application.c
 *
 *  Created on: Nov 1, 2019
 */

#include "Application.h"
extern volatile GUI_TIMER_TIME OS_TimeMS;
/*Uart variables*/
char UartRxData[100];
char UartTxData[100];
/**/
uint8_t Index = 0;
uint16_t SetPoint;
uint16_t SetPointBackup;
bool EncoderChanged=false;
uint8_t ChangedEncoderValueOnScreen=0;
/*Temperature measurement variables*/
float ADCData = 0;
float TEST_ADCData;
float T_tc = 0;
float T_amb = 20;
float U_measured;
const float U_seebeck = 26.2;
const float VoltageMultiplier = 3.662; /*33000000/(4096*220)=3.662*/
uint16_t MovingAverage_T_tc = 0;
uint16_t Points = 0;
bool OutputState = false;
uint8_t FirstRunCounter = 0;
/*PID variables*/
uint8_t OutputDuty = 10;
uint8_t OutputDutyFiltered = 0;
float Ts = 0.11;
uint8_t N = 5;
float Kp = 1.7;
float Ki = 0.15;
float Kd = 0.5;
float E0 = 0;
float E1 = 0;
float E2 = 0;
float U0 = 0;
float U1 = 0;
float U2 = 0;
float a0;
float a1;
float a2;
float b0;
float b1;
float b2;
float A1;
float A2;
float B0;
float B1;
float B2;
/**/
float Derivative=0;
float Integral=0;
float Bias=0;
/**/
/*state machine variables*/
bool SolderingIronIsInHolder;	/*1 if soldering iron is in the Holder*/
bool SolderingTipIsRemoved=false;/*new PCB version can distinguish removed tip and unconnected soldering iron*/
bool SolderingIronNotConnected;/*1 if soldering iron unconnected*/
extern WM_HWIN hDialog;		/**/
extern WM_HWIN hText_0;		/*Set Temperature*/
extern WM_HWIN hText_1;		/*setpoint*/
extern WM_HWIN hText_2;		/*°C*/
extern WM_HWIN hText_3;		/*Soldering Iron Temperature*/
extern WM_HWIN hText_4;		/*actual temp*/
extern WM_HWIN hText_5;		/*°C*/
extern WM_HWIN hText_6;		/*Heating power*/
extern WM_HWIN hProgbar_0;	/*progress bar*/
/*Flash variables*/
bool FlashWriteEnabled=true;
uint16_t VirtAddVarTab;
/**/
uint16_t Counter = 0;
uint8_t Cnt2=0;
bool CounterFlag = false;
/*defines*/
#define BlinkingPeriod 						750									/*ms period time of blinking texts*/
#define ChangedEncoderValueOnScreenPeriod 	4									/*4*BlinkingPeriod*/
#define TemperatureMovingAverageCoeff1 		0.6									/*must be between 0 and 1*/
#define TemperatureMovingAverageCoeff2 		(1-TemperatureMovingAverageCoeff1)
#define OutputDutyFilterCoeff1 				0.5									/*must be between 0 and 1*/
#define OutputDutyFilterCoeff2 				(1-OutputDutyFilterCoeff1)
#define EncoderOffset 						0x7FFF
/**/
/*#define SendMeasurementsTimer*/
#ifdef SendMeasurementsTimer
#define SendMeasurementsPeriod 				110									/*ms*/
#endif

/*Converts a floating point number to string.*/
/*float to char array conversion*/
void ftoa(float n, char *res, int afterpoint) {
	/*Extract integer part*/
	int ipart = (int) n;
	/*Extract floating part*/
	float fpart = n - (float) ipart;

	if (fpart < 0 || ipart < 0) {
		res[0] = '-';
		if (ipart < 0) {
			ipart *= -1;
		}
		if (fpart < 0) {
			fpart *= -1;
		}
		itoa(ipart, res + 1, 10);
	}
	/*convert integer part to string*/
	else {
		itoa(ipart, res, 10);
	}
	int i = strlen(res);
	if (afterpoint != 0) {
		res[i] = '.';
		fpart = fpart * pow(10, afterpoint);
		itoa((int) fpart, res + i + 1, 10);
	}
}
/*send measurements*/
void SendMeasurements(void) {
	char TmpBuffer[20];
	/*Measuring Points*/
	itoa(Points, TmpBuffer, 10);
	strcpy(UartTxData, TmpBuffer);
	strcat(UartTxData, "; ");
	/*ms value*/
	itoa(OS_TimeMS, TmpBuffer, 10);
	strcat(UartTxData, TmpBuffer);
	strcat(UartTxData, "; ");
	/*Output 0 or 1*/
	itoa(OutputState, TmpBuffer, 10);
	strcat(UartTxData, TmpBuffer);
	strcat(UartTxData, "; ");
	/*SetPoint temperature*/
	itoa(SetPoint, TmpBuffer, 10);
	strcat(UartTxData, TmpBuffer);
	strcat(UartTxData, "; ");
	/*Tip temperature*/
	itoa(MovingAverage_T_tc, TmpBuffer, 10);
	strcat(UartTxData, TmpBuffer);
	strcat(UartTxData, "; ");
	/*actual error signal*/
	ftoa(E0, TmpBuffer, 4);
	strcat(UartTxData, TmpBuffer);
	strcat(UartTxData, "; ");
	/*Actual manupilator signal*/
	ftoa(U0, TmpBuffer, 4);
	strcat(UartTxData, TmpBuffer);
	strcat(UartTxData, "; ");
	/*ftoa(U0,TmpBuffer,4)*/
	/*output duty*/
	itoa(OutputDuty, TmpBuffer, 10);
	strcat(UartTxData, TmpBuffer);
	strcat(UartTxData, "\r\n");
	/*send*/
	HAL_UART_Transmit(&huart2, (uint8_t*) UartTxData, strlen(UartTxData), 100);
	Points++;
}
/*PID Continous*/
void PID_Continous(void){
	E1 = E0;
	E0 = SetPoint - T_tc;
	Integral = Integral + (E0 * 0.11);
	if(Integral<-100){
		Integral=-100;
	}
	if(Integral>100){
		Integral=100;
	}
	Derivative = (E0 - E1) / 0.11;
	U0 = Kp*E0 + Ki*Integral + Kd*Derivative + Bias;
	if (U0 > 100) {
		U0 = 100;
	}
	if (U0 < 0) {
		U0 = 0;
	}
	OutputDuty = (((int8_t) U0) / 10) * 10;
	OutputDutyFiltered  = (((uint8_t)(OutputDutyFilterCoeff1*OutputDuty+OutputDutyFilterCoeff2*OutputDutyFiltered))/10)*10;
}
/*external interrupt*/
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
/*----------------------------------------------------------------------------------------------*/
/*Zero Crossing Detector External Interrupt*/
	if (GPIO_Pin == INT_ZC_Pin)
	{
		/*if GPIO==0 falling edge after zero crossing*/
		if (HAL_GPIO_ReadPin(INT_ZC_GPIO_Port, INT_ZC_Pin) == 1)
			{
			if (Index == 0) /*under the first half-wave ADC measurement is performed*/
				{
#ifdef DEBUG
				ADCData = TEST_ADCData;

#elif			/*ACD+precision OPA*/
				ADCData = 0;				/*clear the variable*/

				HAL_GPIO_WritePin(INH_ADC_GPIO_Port, INH_ADC_Pin,GPIO_PIN_RESET); /*Release the ADC input*/

				/*Start AD conversion*/
				HAL_ADC_Start(&hadc1);

				if (HAL_ADC_PollForConversion(&hadc1, 1000) == HAL_OK) /*ADC read*/
				{
					ADCData = HAL_ADC_GetValue(&hadc1); /*Add new adc value to the variable*/
				}
				HAL_GPIO_WritePin(INH_ADC_GPIO_Port, INH_ADC_Pin,GPIO_PIN_SET); /*Pull down the the ADC input*/
				HAL_ADC_Stop(&hadc1); /*stop the ADC module*/
#endif
				if (ADCData > 3500)
				{
					SolderingTipIsRemoved = true;
					OutputState = false;
					OutputDuty = 0;
				}
				else
				{
					SolderingTipIsRemoved = false;
					OutputState = true;
					/*convert to celsius*/
					U_measured = ADCData * VoltageMultiplier; /*measured TC voltage in microvolts = Uadc(LSB) *3.662*/
					T_tc = (U_measured / U_seebeck) + T_amb; /*Termocoulpe temperature=Measured voltage/seebeck voltage+Ambient temperature (cold junction compensation)*/
					MovingAverage_T_tc = (uint16_t)(T_tc * TemperatureMovingAverageCoeff1 + MovingAverage_T_tc * TemperatureMovingAverageCoeff2);/*exponential filter with 2 sample and lambda=0.8*/
					MovingAverage_T_tc = ((MovingAverage_T_tc + 4) / 5) * 5;/*rounding to 0 or 5 MovingAverage_T_tc=T_tc;*/
					if (MovingAverage_T_tc > SetPoint * 1.1)
					{
						OutputState = false;
					}
				}
				if(FirstRunCounter < NumberOfADCSampleAvegrage)
				{
					OutputState = false;
					FirstRunCounter++;
				}
#ifdef	PID_CTRL
				/*PID start*/
				PID_Continous();

				if (OutputState == false)
				{
					OutputDuty = 0;
				}
				/*PID end*/
#endif
			}
			Index++;
			if (Index == 11)
			{
				Index = 0;
			}
		}
		/*rising edge before zero crossing*/
		if (HAL_GPIO_ReadPin(INT_ZC_GPIO_Port, INT_ZC_Pin) == 0)
		{
			if (Index == 0)
			{
				HAL_GPIO_WritePin(HEATING_GPIO_Port, HEATING_Pin, GPIO_PIN_RESET); /*output off*/
			}
			else
			{
				if (OutputState == true)
				{
#ifdef HYST_CTRL
					if (HAL_GPIO_ReadPin(HEATING_GPIO_Port, HEATING_Pin) == 1) /*Output=1*/
						{
						if (MovingAverage_T_tc >= (SetPoint + 5))
						{
							HAL_GPIO_WritePin(HEATING_GPIO_Port, HEATING_Pin,GPIO_PIN_RESET); /*output off*/
						}
					}
					if (HAL_GPIO_ReadPin(HEATING_GPIO_Port, HEATING_Pin) == 0)  /*Output=0*/
						{
						if (MovingAverage_T_tc <= (SetPoint - 5))
						{
							HAL_GPIO_WritePin(HEATING_GPIO_Port, HEATING_Pin,GPIO_PIN_SET); /*output on*/
						}
					}
#endif
#ifdef PID_CTRL
					if (Index <= (OutputDuty / 10))
					{
						HAL_GPIO_WritePin(HEATING_GPIO_Port, HEATING_Pin,GPIO_PIN_SET); /*output on*/
					}
					else
					{
						HAL_GPIO_WritePin(HEATING_GPIO_Port, HEATING_Pin,GPIO_PIN_RESET); /*output off*/
					}
#endif
				}
				else
				{
					HAL_GPIO_WritePin(HEATING_GPIO_Port, HEATING_Pin,GPIO_PIN_RESET); /*output off*/
				}
			}
		}
	}
/*----------------------------------------------------------------------------------------------*/
/*Encoder Button External Interrupt*/
	if (GPIO_Pin == ENC_BUT_Pin)
		{
		if (HAL_GPIO_ReadPin(ENC_BUT_GPIO_Port, ENC_BUT_Pin) == 0)  /*if GPIO==0 -> falling edge*/
		{
		}
		if (HAL_GPIO_ReadPin(ENC_BUT_GPIO_Port, ENC_BUT_Pin) == 1)  /*rising edge*/
		{
			/*store actual encoder value to flash*/
			if (FlashWriteEnabled)
			{
				ChangedEncoderValueOnScreen=ChangedEncoderValueOnScreenPeriod;
				uint16_t tmpWrite = SetPointBackup / 10;
				uint16_t tmpRead;
				if((EE_ReadVariable(0x0001,  &tmpRead)) != HAL_OK)
				{
					Error_Handler();
				}
				if (tmpRead != tmpWrite)
				{
					if((EE_WriteVariable(0x0001,  tmpWrite)) != HAL_OK)
					{
						Error_Handler();
					}
					if((EE_ReadVariable(0x0001,  &tmpRead)) != HAL_OK)
					{
						Error_Handler();
					}
					if (tmpWrite != tmpRead)
					{
						/*flash write error*/
						asm("nop");/*debugnop*/
					}
					else
					{
						/*flash write ok*/
						asm("nop");/*debugnop*/
					}
				}
			}
			else
			{
				asm("nop");/*debugnop*/
			}
		}
	}
/*----------------------------------------------------------------------------------------------*/
/*Sleep Pin External Interrupt*/
	if (GPIO_Pin == SLEEP_Pin)
	{

	}
}
/*system timer 1ms*/
void HAL_SYSTICK_Callback(void)
{
	Counter++;
	if (Counter == BlinkingPeriod)
	{
		if (CounterFlag)
		{
			CounterFlag = false;
		} else
		{
			CounterFlag = true;
		}
		if(ChangedEncoderValueOnScreen>0)
		{
			ChangedEncoderValueOnScreen--;
		}
		Counter = 0;
	}
#ifdef SendMeasurementsTimer
	Cnt2++;
	if(Cnt2==SendMeasurementsPeriod){
		SendMeasurements();
		Cnt2=0;
	}
#endif
}
/*Uart functions*/
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
	if (huart->Instance == USART2)
	{
		/*START: Kp=1.00, Ki=2.00, Kd=0.00 :END*/
		/*interpreting the incoming data*/
		if(		UartRxData[0]=='S' &&
				UartRxData[1]=='T' &&
				UartRxData[2]=='A' &&
				UartRxData[3]=='R' &&
				UartRxData[4]=='T' &&
				UartRxData[5]==':' &&
				UartRxData[6]==' ' &&
				/*Kp*/
				UartRxData[7]=='K' &&
				UartRxData[8]=='p' &&
				UartRxData[9]=='=' &&
				(UartRxData[10]>='0' && UartRxData[10]<='9') &&
				UartRxData[11]=='.' &&
				(UartRxData[12]>='0' && UartRxData[12]<='9') &&
				(UartRxData[13]>='0' && UartRxData[13]<='9') &&
				UartRxData[14]==',' &&
				UartRxData[15]==' ' &&
				/*Ki*/
				UartRxData[16]=='K' &&
				UartRxData[17]=='i' &&
				UartRxData[18]=='=' &&
				(UartRxData[19]>='0' && UartRxData[19]<='9') &&
				UartRxData[20]=='.' &&
				(UartRxData[21]>='0' && UartRxData[21]<='9') &&
				(UartRxData[22]>='0' && UartRxData[22]<='9') &&
				UartRxData[23]==',' &&
				UartRxData[24]==' ' &&
				/*Kd*/
				UartRxData[25]=='K' &&
				UartRxData[26]=='d' &&
				UartRxData[27]=='=' &&
				(UartRxData[28]>='0' && UartRxData[28]<='9') &&
				UartRxData[29]=='.' &&
				(UartRxData[30]>='0' && UartRxData[30]<='9') &&
				(UartRxData[31]>='0' && UartRxData[31]<='9') &&
				UartRxData[32]==' ' &&
				/**/
				UartRxData[33]==':' &&
				UartRxData[34]=='E' &&
				UartRxData[35]=='N' &&
				UartRxData[36]=='D' &&
				UartRxData[37]=='\r' &&
				UartRxData[38]=='\n' )
		{
			Kp=(UartRxData[10]-'0')+(0.1*(UartRxData[12]-'0'))+(0.01*(UartRxData[13]-'0'));
			Ki=(UartRxData[19]-'0')+(0.1*(UartRxData[21]-'0'))+(0.01*(UartRxData[22]-'0'));
			Kd=(UartRxData[28]-'0')+(0.1*(UartRxData[30]-'0'))+(0.01*(UartRxData[31]-'0'));
			if((EE_WriteVariable(0x0002,  (uint16_t)(Kp*100))) != HAL_OK)
			{
				Error_Handler();
			}
			if((EE_WriteVariable(0x0003,  (uint16_t)(Ki*100))) != HAL_OK)
			{
				Error_Handler();
			}
			if((EE_WriteVariable(0x0004,  (uint16_t)(Kd*100))) != HAL_OK)
			{
				Error_Handler();
			}
		}
		else
		{
			HAL_UART_Transmit_IT(&huart2, (uint8_t*) "Wrong format\r\n", 12);
		}
		HAL_UART_Receive_IT(&huart2, (uint8_t*)UartRxData, 39);
	}
}
/**/
void HAL_UART_ErrorCallback(UART_HandleTypeDef *huart)
{
	if (huart->ErrorCode == HAL_UART_ERROR_ORE)
	{
		HAL_UART_Transmit_IT(&huart2, (uint8_t*) "FAIL\r\n", 6);
		HAL_UART_Receive_IT(&huart2, (uint8_t*)UartRxData, 39);
	}
}
/**/
void StateMachine(void)
{
	if(HAL_GPIO_ReadPin(SLEEP_GPIO_Port,SLEEP_Pin)==1)
	{
		SolderingIronIsInHolder=true;/*Soldering iron is in the holder*/
	}
	else
	{
		SolderingIronIsInHolder=false;/*Soldering iron is not in the holder*/
	}
	/*locals*/
	char TmpStr[5];
	uint16_t EncoderReadValue;
	/**/
	if(HAL_GPIO_ReadPin(SNC_GPIO_Port,SNC_Pin)==1)/*soldering iron is connected*/
	{
		SolderingIronNotConnected=false;
	}
	else
	{
		SolderingIronNotConnected=true;
	}
	/**/
	if(TIM2->CNT<0x8009)/*if encoder less than 0x7FFF+0x000A=0x8009 - 100°C*/
	{
		TIM2->CNT=0x8009;/*low level saturation at 0x8009*/
	}
	if(TIM2->CNT>0x802C)/*if encoder bigger than 0x7FFF+0x002D=0x802C - 450°C*/
	{
		TIM2->CNT=0x802C;/*top level saturation at 0x802C*/
	}
	EncoderReadValue=(TIM2->CNT-0x7FFF)*10;
	if(EncoderReadValue!=SetPointBackup)
	{
		ChangedEncoderValueOnScreen=ChangedEncoderValueOnScreenPeriod;
	}
	SetPointBackup=EncoderReadValue;/*setpoint is 10*Encoder data-EncoderOffset*/
	/**/
	if(SolderingTipIsRemoved==true||SolderingIronNotConnected==true)
	{
		PROGBAR_SetValue(hProgbar_0, 0);/*output duty*/
		if(CounterFlag){
			TEXT_SetText(hText_4, "0");
			if(SolderingTipIsRemoved==true)
			{
				TEXT_SetText(hText_6, "Soldering tip is removed!");
			}
			if(SolderingIronNotConnected==true)
			{
				TEXT_SetText(hText_6, "Soldering iron is not connected!");
			}
		}
		else
		{
			TEXT_SetText(hText_4, " ");
			TEXT_SetText(hText_6, " ");
		}
		/**/
	    TEXT_SetText(hText_0, "Soldering\n Temperature");
		sprintf(TmpStr,"%u",SetPointBackup);
		TEXT_SetText(hText_2, TmpStr);
		SetPoint=SetPointBackup;
	}
	else
	{
		TEXT_SetText(hText_6, "Heating Power");
		PROGBAR_SetValue(hProgbar_0, OutputDutyFiltered);/*output duty*/
		sprintf(TmpStr,"%u",MovingAverage_T_tc);/*Soldering iron tip temperature*/
		TEXT_SetText(hText_4, TmpStr);
		/**/
		if(SolderingIronIsInHolder == true)
		{
			if(SetPointBackup>150)
			{
				SetPoint=150;
			}
			else
			{
				SetPoint=SetPointBackup;
			}
			if(ChangedEncoderValueOnScreen>0)
			{
			    TEXT_SetText(hText_0, "Soldering\n Temperature");
				sprintf(TmpStr,"%u",SetPointBackup);
				TEXT_SetText(hText_2, TmpStr);
			}
			else
			{
				if(CounterFlag)
				{
				    TEXT_SetText(hText_0, "Soldering\n Temperature");
					sprintf(TmpStr,"%u",SetPointBackup);
					TEXT_SetText(hText_2, TmpStr);
				}
				else
				{
				    TEXT_SetText(hText_0, "Sleep\n Temperature");
				    sprintf(TmpStr,"%u",SetPoint);
				    TEXT_SetText(hText_2, TmpStr);/*sleep temperature*/
				}
			}
		}
		else
		{
		    TEXT_SetText(hText_0, "Soldering\n Temperature");
			sprintf(TmpStr,"%u",SetPointBackup);
			TEXT_SetText(hText_2, TmpStr);
			SetPoint=SetPointBackup;
		}
	}
}
/**/
void MainInit(void) {
	uint16_t tmp = 0;
	HAL_TIM_Encoder_Start(&htim2,TIM_CHANNEL_ALL);/*encoder timer2*/
	/*read stored temperature value from flash*/
	HAL_FLASH_Unlock();
	if (EE_Init() != EE_OK)
	{
		Error_Handler();
	}
	if ((EE_ReadVariable(0x0001, &tmp)) == HAL_OK)
	{
		TIM2->CNT = (uint8_t) tmp + EncoderOffset;
	}
	else
	{
		TIM2->CNT = 10 + EncoderOffset;/*safety default 100°C*/
	}
	if ((EE_ReadVariable(0x0002, &tmp)) == HAL_OK) /*Kp*/
	{
		Kp=tmp;
		Kp/=100;
	}
	else
	{
		Kp=1.7;
	}
	/**/
	if ((EE_ReadVariable(0x0003, &tmp)) == HAL_OK) /*Ki*/
	{
		Ki=tmp;
		Ki/=100;
	}
	else
	{
		Ki=0.15;
	}
	/**/
	if ((EE_ReadVariable(0x0004, &tmp)) == HAL_OK) /*Kd*/
	{
		Kd=tmp;
		Kd/=100;
	}
	else
	{
		Kd=0.5;
	}
	/**/
	HAL_UART_Receive_IT(&huart2, (uint8_t*)UartRxData, 39);
	SetPointBackup=(TIM2->CNT-0x7FFF)*10;
	/**/
	HAL_NVIC_EnableIRQ(EXTI9_5_IRQn);/*enable zero crossing interrupt*/
}
