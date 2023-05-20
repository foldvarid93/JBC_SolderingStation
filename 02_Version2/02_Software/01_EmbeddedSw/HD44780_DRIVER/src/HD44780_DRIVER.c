/*
 * Application.c
 *
 *  Created on: Nov 1, 2019
 */

#include "Application.h"
#ifdef LCDTFT
extern volatile GUI_TIMER_TIME OS_TimeMS;
#endif
#ifdef HD44780
uint32_t OS_TimeMS;
#endif
//Uart vasiables
char UartRxData[100];
char UartTxData[100];
//
uint8_t Index = 0;
uint16_t SetPoint;
uint16_t SetPointBackup;
bool EncoderChanged=false;
uint8_t ChangedEncoderValueOnScreen=0;
//Temperature measurement varables
float ADCData = 0;
float TEST_ADCData;
float T_tc = 0;
float T_amb = 20;
float U_measured;
const float U_seebeck = 26.2;
const float VoltageMultiplier = 3.662; //33000000/(4096*220)=3.662
uint16_t MovingAverage_T_tc = 0;
uint16_t Points = 0;
bool OutputState = false;
uint8_t FirstRunCounter = 0;
//PID variables
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
//
float Derivative=0;
float Integral=0;
float Bias=0;
//
//const uint16_t EncoderOffset = 0x7FFF;
//state machine variables
bool SolderingIronIsInHolder;//1 if soldering iron is in the Holder
bool SolderingTipIsRemoved=false;//new PCB version can distinguish removed tip and unconnected soldering iron
#ifdef LCDTFT
bool SolderingIronNotConnected;//1 if soldering iron unconnected
extern WM_HWIN hDialog;//
extern WM_HWIN hText_0;//Set Temperature
extern WM_HWIN hText_1;//setpoint
extern WM_HWIN hText_2;//�C
extern WM_HWIN hText_3;//Soldering Iron Temperature
extern WM_HWIN hText_4;//actual temp
extern WM_HWIN hText_5;//�C
extern WM_HWIN hText_6;//Heating power
extern WM_HWIN hProgbar_0;//progress bar
#endif
//Flash variables
bool FlashWriteEnabled=true;
uint16_t VirtAddVarTab;//[NB_OF_VAR] = {0x0001};
//
uint16_t Counter = 0;
uint8_t Cnt2=0;
bool CounterFlag = false;
//defines
#define BlinkingPeriod 750//ms period time of blinking texts
#define ChangedEncoderValueOnScreenPeriod 4//4*BlinkingPeriod
#define TemperatureMovingAverageCoeff1 0.6 /*must be between 0 and 1*/
#define TemperatureMovingAverageCoeff2 (1-TemperatureMovingAverageCoeff1)
#define OutputDutyFilterCoeff1 50//must be between 0 and 1
#define OutputDutyFilterCoeff2 (100-OutputDutyFilterCoeff1)
#define EncoderOffset 0x7FFF
//
//#define SendMeasurementsTimer
#ifdef SendMeasurementsTimer
#define SendMeasurementsPeriod 110//ms
#endif
/* USER CODE END PV */
//
#ifdef LCDTFT
extern void Init_GUI(void);
#endif
//
// Converts a floating point number to string.
//float to char array conversion
void ftoa(float n, char *res, int afterpoint) {
	// Extract integer part
	int ipart = (int) n;
	// Extract floating part
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
	// convert integer part to string
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

void LCD_text(const char *q) {
	while (*q) {
		LCD_write(*q++, 0xFF);
	}
}
void LCD_write(unsigned char c, unsigned char d) {
	if (d == 0x00) {
		HAL_GPIO_WritePin(LCD_RS_GPIO_Port, LCD_RS_Pin, GPIO_PIN_RESET);
	} else {
		HAL_GPIO_WritePin(LCD_RS_GPIO_Port, LCD_RS_Pin, GPIO_PIN_SET);
	}
	HAL_Delay(1);
	LCD_DATA_PORT->ODR &= 0xFFFFFF00;
	LCD_DATA_PORT->ODR |= c;
	HAL_GPIO_WritePin(LCD_E_GPIO_Port, LCD_E_Pin, GPIO_PIN_SET);
	asm("nop");
	HAL_GPIO_WritePin(LCD_E_GPIO_Port, LCD_E_Pin, GPIO_PIN_RESET);
}
void LCD_init(void) {
	user_pwm_setvalue(100);
	HAL_GPIO_WritePin(GPIOB, LCD_E_Pin, GPIO_PIN_RESET);
	HAL_GPIO_WritePin(LCD_RS_GPIO_Port, LCD_RS_Pin, GPIO_PIN_RESET);
	HAL_GPIO_WritePin(LCD_RW_GPIO_Port, LCD_RW_Pin, GPIO_PIN_RESET);

	HAL_Delay(100);
	LCD_write(0x38, 0x00);
	HAL_Delay(1);
	LCD_write(0x38, 0x00);
	HAL_Delay(1);
	LCD_write(0x38, 0x00);
	LCD_write(0x38, 0x00);
	LCD_write(0x38, 0x00);
	LCD_write(0x0C, 0x00); // Make cursorinvisible
	LCD_write(0x01, 0x00);
	HAL_Delay(2);
	LCD_write(0x6, 0x00); // Set entry Mode(auto increment of cursor)

	LCD_write(0x01, 0x00);
	HAL_Delay(2);
	LCD_write(0x80, 0x00);
	LCD_text("Set Temp:");
	LCD_write(0x8E, 0x00);
	LCD_text("C");
	LCD_write(0xC0, 0x00);
	LCD_text("Iron Temp:");
	LCD_write(0xD4, 0x00);
	LCD_text("");
	LCD_write(0x94, 0x00);
	LCD_text("");
}
//PWM LCD backlight
void user_pwm_setvalue(uint16_t value) {
	TIM_OC_InitTypeDef sConfigOC;

	sConfigOC.OCMode = TIM_OCMODE_PWM1;
	sConfigOC.Pulse = value;
	sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
	sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
	HAL_TIM_PWM_ConfigChannel(&htim3, &sConfigOC, TIM_CHANNEL_1);
	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
}
//
//
void StateMachine(void){
	if(HAL_GPIO_ReadPin(SLEEP_GPIO_Port,SLEEP_Pin)==1){
		SolderingIronIsInHolder=true;//Soldering iron is in the holder
	}
	else{
		SolderingIronIsInHolder=false;//Soldering iron is not in the holder
	}
#ifdef LCDTFT
	//locals
	char TmpStr[5];
	uint16_t EncoderReadValue;
	//
	if(HAL_GPIO_ReadPin(SNC_GPIO_Port,SNC_Pin)==1){//soldering iron is connected
		SolderingIronNotConnected=false;
	}
	else{
		SolderingIronNotConnected=true;
	}
	//
	if(TIM2->CNT<0x8009){//if encoder less than 0x7FFF+0x000A=0x8009 - 100�C
		TIM2->CNT=0x8009;//low level saturation at 0x8009
	}
	if(TIM2->CNT>0x802C){//if encoder bigger than 0x7FFF+0x002D=0x802C - 450�C
		TIM2->CNT=0x802C;//top level saturation at 0x802C
	}
	EncoderReadValue=(TIM2->CNT-0x7FFF)*10;
	if(EncoderReadValue!=SetPointBackup){
		ChangedEncoderValueOnScreen=ChangedEncoderValueOnScreenPeriod;
	}
	SetPointBackup=EncoderReadValue;//setpoint is 10*Encoder data-EncoderOffset

	uint8_t TmpBuf[40];
	if (TIM2->CNT < 0x8009) {
		TIM2->CNT = 0x8009;
	}
	if (TIM2->CNT > 0x802C) {
		TIM2->CNT = 0x802C;
	}
	SetPointBackup = (TIM2->CNT - EncoderOffset) * 10;
	//setpoint
	uint16_t temp = SetPointBackup;
	uint8_t i = 0;
	TmpBuf[i] = (temp / 100) + 0x30;		//százas
	if (TmpBuf[i] != '0') {
		i++;
	}
	temp %= 100;
	TmpBuf[i++] = (temp / 10) + 0x30;		//tizes
	temp %= 10;
	TmpBuf[i++] = temp + 0x30;		//egyes
	TmpBuf[i++] = ' ';
	TmpBuf[i++] = 0xDF;		//Celsius fok
	TmpBuf[i++] = 'C';
	TmpBuf[i++] = ' ';
	TmpBuf[i++] = '\0';
	LCD_write(0x8A, 0x00);		//LCD első sor
	LCD_text((const char*) TmpBuf);

	//actual temperature
	if (SolderingTipIsRemoved) {
		temp = 0;
	} else {
		temp = MovingAverage_T_tc;
	}
	i = 0;
	if(temp==0){
		TmpBuf[i++]='0';
	}
	else{
		TmpBuf[i] = (temp / 100) + 0x30;		//százas
		if (TmpBuf[i] != '0') {
			i++;
		}
		temp %= 100;
		TmpBuf[i++] = (temp / 10) + 0x30;		//tizes
		temp %= 10;
		TmpBuf[i++] = temp + 0x30;		//egyes
	}
	TmpBuf[i++] = ' ';
	TmpBuf[i++] = 0xDF;		//Celsius fok
	TmpBuf[i++] = 'C';
	TmpBuf[i++] = ' ';
	TmpBuf[i++] = ' ';
	TmpBuf[i++] = '\0';
	LCD_write(0xCB, 0x00);		//
	LCD_text((const char*) TmpBuf);
	//Sleep
	if (SolderingTipIsRemoved==1) {
		FlashWriteEnabled=false;
		LCD_write(0x94, 0x00);
		LCD_text("Iron Is Unconnected!");
	} else if (SolderingIronIsInHolder==1) {
		FlashWriteEnabled=false;
		LCD_write(0x94, 0x00);
		LCD_text("Sleep temp: 150");
		LCD_write(0xDF, 0xFF);		//Celsius fok
		LCD_write('C', 0xFF);
		SetPointBackup = SetPoint;
		if (SetPoint > 150) {
			SetPoint = 150;
		}
	} else {
		FlashWriteEnabled=true;
		LCD_write(0x94, 0x00);
		LCD_text("                    ");
		SetPoint = SetPointBackup;
	}
	if (OutputState) {
		LCD_write(0xD4, 0x00);
		LCD_text("Output: ON ");
	} else {
		LCD_write(0xD4, 0x00);
		LCD_text("Output: OFF");
	}
}

void MainInit(void)
{
	uint16_t tmp = 0;
	HAL_TIM_Encoder_Start(&htim2,TIM_CHANNEL_ALL);//encoder timer2

	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);//backlight PWM timer
	user_pwm_setvalue(100);//set pwm max
	LCD_init();//init HD44780 LCD

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
		TIM2->CNT = 10 + EncoderOffset;//safety default 100�C
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
	//
	if ((EE_ReadVariable(0x0003, &tmp)) == HAL_OK) /*Ki*/
	{
		Ki=tmp;
		Ki/=100;
	}
	else
	{
		Ki=0.15;
	}
	//
	if ((EE_ReadVariable(0x0004, &tmp)) == HAL_OK) /*Kd*/
	{
		Kd=tmp;
		Kd/=100;
	}
	else
	{
		Kd=0.5;
	}
	//
	HAL_UART_Receive_IT(&huart2, (uint8_t*)UartRxData, 39);
	SetPointBackup=(TIM2->CNT-0x7FFF)*10;
	//
	HAL_NVIC_EnableIRQ(EXTI9_5_IRQn);//enable zero crossing interrupt
}
