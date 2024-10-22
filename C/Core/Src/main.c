/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2024 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "rtc.h"
#include "spi.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

#include <string.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>

// Peripheral
#include "ultrasonic.h"
#include "delay.h"
#include "dht11.h"
#include "alarm.h"


// Graphic LCD library
#include "ssd1306.h"
#include "ssd1306_conf.h"
#include "ssd1306_fonts.h"
#include "ssd1306_tests.h"




/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */





/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

// Uart2_Set

#ifdef __GNUC__
  /* With GCC, small printf (option LD Linker->Libraries->Small printf
     set to 'Yes') calls __io_putchar() */
  #define PUTCHAR_PROTOTYPE int __io_putchar(int ch)
#else
  #define PUTCHARPROTOTYPE int fputc(int ch, FILE *f)
#endif /* __GNUC__ */
PUTCHAR_PROTOTYPE
{
  /* Place your implementation of fputc here */
  /* e.g. write a character to the EVAL_COM1 and Loop until the end of transmission */
  HAL_UART_Transmit(&huart2, (uint8_t *)&ch, 1, 0xFF);

  return ch;
}

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */


// RTC_Handler
RTC_TimeTypeDef sTime;
RTC_DateTypeDef sDate;
RTC_AlarmTypeDef sAlarm;


// RTC_Data
char temp_date[10];
char temp_time[10];
char temp_day[10];
char temp_ampm[5];
char temp_alarm[10];

char ampm[2][3] = {"AM", "PM"};
const char* weekDayStrings[8] = {"", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};


// Text
char text_Stop_Watch[]= "Stopwatch";
char text_Timer[]= "Timer";
char text_Alarm[]= "Alarm";
char text_Basys[]= "Basys";


// Uart Callback (uart2)
uint8_t rx ;
uint8_t buffindex=0;
uint8_t buff[30];
uint8_t currentAMPM = 0; // 0: AM, 1: PM


// Analog Clock
#define CENTER_X 32
#define CENTER_Y 32
#define HOUR_HAND_LENGTH 19
#define MINUTE_HAND_LENGTH 22
#define SECONDS_HAND_LENGTH 27
#define DEG_TO_RAD(deg) ((deg) * (M_PI / 180.0))

volatile int xHour, yHour, xMinute, yMinute, xSeconds, ySeconds;


// Blue Tooth (uart6)
volatile uint8_t tx;


// Stop_watch
char temp_stop_watch[10] = "00:00:00";
volatile uint8_t send_uart_sw = 0;
volatile uint8_t sw_start_stop = 0;
volatile uint32_t sw_minutes = 0;
volatile uint32_t sw_seconds = 0;
volatile uint32_t sw_milliseconds = 0;



// Timer
char temp_timer_watch[10] = "00:00:00";
volatile uint8_t timer_start_stop = 0;
volatile uint32_t timer_hour = 0;
volatile uint32_t timer_minutes = 0;
volatile uint32_t timer_seconds = 0;


// Smart_Watch_Update
volatile uint8_t current_watch_state = 'R';


// basys <---> stm32 date
char temp_basys_date[10] = {0};		// rx_basys_data * 2
char temp_basys_time[10] = {0};		// rx_basys_data * 2


uint8_t rx_basys [8];  			// Basys3 -> STM32
uint8_t stm32_bcd_data[7];	// STM32 -> Basys3

uint8_t flag_basys = 0;
uint8_t basys_count;

volatile uint32_t basys_hours;
volatile uint32_t basys_minutes;
volatile uint32_t basys_seconds;


/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */



//////////////////////////////////////// --Smartwatch--/////////////////////////////////////////////////////

void Smart_Watch_Lcd_Refresh()
{
	switch(current_watch_state)
	{
		case '0' :
				break;

		case 'F' :
				Smart_Watch_Timer(temp_timer_watch);
				break;

		case 'B' :
				Smart_Watch_Stop(temp_stop_watch);
				break;

		case 'L' :
				Smart_Watch_Analog(temp_date, temp_buffer, temp_day, temp_ampm);
				break;

		case 'R' :
				Smart_Watch_Main(temp_date, temp_time, temp_buffer, temp_day, temp_ampm);
				break;

		case 'C' :
				Smart_Watch_Alarm(temp_alarm);
				break;

		case 'T' :
				//Smart_Watch_STM32_Basys();
		        Smart_Watch_Sleepmode();
				break;

		case 'X' :

				if (flag_basys)
				{
				    ssd1306_Fill(Black);

					ssd1306_SetCursor(1,1);
					ssd1306_WriteString(text_Basys, Font_7x10, White);

				    ssd1306_SetCursor(70,1);
					ssd1306_WriteString(temp_basys_date, Font_7x10, White);

				    ssd1306_SetCursor(18,30);
					ssd1306_WriteString(temp_basys_time, Font_11x18, White);

				    ssd1306_UpdateScreen();

				}

      	  	    else
				{
					Smart_Watch_Basys_STM32();
				}

				break;

		default :
				Smart_Watch_Main(temp_date, temp_buffer, temp_day, temp_ampm);
				break;
	}
}



void Smart_Watch_Update(uint8_t tx, char *alarm_time, char *temp_stop_watch)
{

/*
    if (tx == '0')
    {
        tx = current_watch_state;

    }
    else if (tx != 'S' && tx != 'C')
    {
    	current_watch_state = tx;
    }
*/

	switch(tx)
	{

		case '0' :
				break;

		case 'F' :
				current_watch_state = 'F';
				Smart_Watch_Timer(temp_timer_watch);
            	break;

		case 'B' :
				current_watch_state = 'B';
				Smart_Watch_Stop(temp_stop_watch);
            	break;

		case 'L' :
				current_watch_state = 'L';
				Smart_Watch_Analog(temp_date, temp_buffer, temp_day, temp_ampm);
				break;

		case 'R' :
				current_watch_state = 'R';
				Smart_Watch_Main(temp_date, temp_time, temp_buffer, temp_day, temp_ampm);
            	break;

		case 'C' :
				current_watch_state = 'C';
				Smart_Watch_Alarm(alarm_time);
				break;

		case 'X' :
				current_watch_state = 'X';
				//Smart_Watch_Basys_STM32();
				break;

		case 'S' :

			if(current_watch_state == 'C') Alarm_On_Off();

			else if(current_watch_state == 'B')
			{
				Stop_Watch_Start_Stop(2);
				sw_minutes = 0; sw_seconds = 0; sw_milliseconds = 0;
				sprintf(temp_stop_watch, "%02lu:%02lu:%02lu\n", sw_minutes, sw_seconds, sw_milliseconds);
			}

			else if(current_watch_state == 'F')
			{
				Timer_Watch_Start_Stop(2);
				timer_hour = 0; timer_minutes = 0; timer_seconds = 0;
				sprintf(temp_timer_watch, "%02lu:%02lu:%02lu\n", timer_hour, timer_minutes, timer_seconds);
			}
				break;

		case 'T' :
				current_watch_state = 'T';
				//Smart_Watch_STM32_Basys();
		        Smart_Watch_Sleepmode();
            	break;

		case 'A' :
			if(current_watch_state == 'B') Stop_Watch_Start_Stop(1);

			else if(current_watch_state == 'F')
			{
			    if (timer_hour == 0 && timer_minutes == 0 && timer_seconds == 0)
			    {
			    	Timer_Watch_Start_Stop(2);
			    }

			    else Timer_Watch_Start_Stop(1);
			}

			else if(current_watch_state == 'T')
			{
				HAL_UART_Transmit(&huart6, (uint8_t*)stm32_bcd_data, sizeof(stm32_bcd_data), 10);
			}

			else if(current_watch_state == 'X')
			{
				//HAL_UART_Init(&huart6);
				HAL_UART_Receive_IT(&huart6, rx_basys, 7);

			}
				break;

		case 'P' :
			if(current_watch_state == 'B') Stop_Watch_Start_Stop(2);
			else if(current_watch_state == 'F') Timer_Watch_Start_Stop(2);

			else if(current_watch_state == 'T')
			{
				HAL_UART_AbortTransmit_IT(&huart6);
				Smart_Watch_STM32_Basys();
			}

			else if(current_watch_state == 'X')
			{
				//HAL_UART_DeInit(&huart6);
				Smart_Watch_Basys_STM32();
			}
				break;


		default :
				Smart_Watch_Main(temp_date, temp_buffer, temp_day, temp_ampm);
				break;
	}
}





void Smart_Watch_STM32_Basys()  // T
{
	ssd1306_Github();
}


void Smart_Watch_Basys_STM32()	// X
{
	ssd1306_Garfield();
}





void Smart_Watch_Sleepmode()
{
	if (distance > 30)
		  {
		      //ssd1306_Garfield();
		      ssd1306_Github();
		  }
	else Smart_Watch_Main(temp_date, temp_buffer, temp_day, temp_ampm);
}




void DrawClockHands(uint8_t hour_BCD, uint8_t minute_BCD, uint8_t seconds_BCD)
{
    float hourAngle, minuteAngle, secondsAngle;

    uint8_t hour_value = (hour_BCD >> 4) * 10 + (hour_BCD & 0x0f);
    uint8_t minute_value = (minute_BCD >> 4) * 10 + (minute_BCD & 0x0f);
    uint8_t seconds_value = (seconds_BCD >> 4) * 10 + (seconds_BCD & 0x0f);

    // Calculate hour hand angle (12 hours = 360 degrees)
    hourAngle = (hour_value % 12) * 30 + (minute_value / 2.5); // Each hour represents 30 degrees
    // Calculate minute hand angle (60 minutes = 360 degrees)
    minuteAngle = minute_value * 6; // Each minute represents 6 degrees
    secondsAngle = seconds_value * 6;

    // Calculate end point of hour hand
    xHour = CENTER_X + (int)(HOUR_HAND_LENGTH * cos(DEG_TO_RAD(hourAngle - 90)));
    yHour = CENTER_Y + (int)(HOUR_HAND_LENGTH * sin(DEG_TO_RAD(hourAngle - 90)));

    // Calculate end point of minute hand
    xMinute = CENTER_X + (int)(MINUTE_HAND_LENGTH * cos(DEG_TO_RAD(minuteAngle - 90)));
    yMinute = CENTER_Y + (int)(MINUTE_HAND_LENGTH * sin(DEG_TO_RAD(minuteAngle - 90)));

    // Calculate end point of minute hand
    xSeconds = CENTER_X + (int)(SECONDS_HAND_LENGTH * cos(DEG_TO_RAD(secondsAngle - 90)));
    ySeconds = CENTER_Y + (int)(SECONDS_HAND_LENGTH * sin(DEG_TO_RAD(secondsAngle - 90)));

    // Draw hour hand
    ssd1306_Line(CENTER_X, CENTER_Y, xHour, yHour, White);

    // Draw minute hand
    ssd1306_Line(CENTER_X, CENTER_Y, xMinute, yMinute, White);

    // Draw minute hand
    ssd1306_Line(CENTER_X, CENTER_Y, xSeconds, ySeconds, White);

}



void Smart_Watch_Analog(char* temp_date, char* temp_buffer, char* temp_day, char* temp_ampm)
{

    // Clear the screen and set it to black
    ssd1306_Fill(Black);

    // Draw a circle to represent the clock face
    ssd1306_DrawCircle(32,32,31,White);

    // Display the date on the screen
    ssd1306_SetCursor(73,10);
    ssd1306_WriteString(temp_date, Font_6x8, White);

    ssd1306_DrawCircle(xHour, yHour, 2, White);

    // Display the time buffer on the screen
    ssd1306_SetCursor(73,30);
    ssd1306_WriteString(temp_buffer, Font_6x8, White);

    // Display the day of the week on the screen
    ssd1306_SetCursor(73,50);
    ssd1306_WriteString(temp_day, Font_6x8, White);

    // Display AM or PM indicator on the screen
    ssd1306_SetCursor(1,1);

    char temp_str_ampm[3];
    	 temp_str_ampm[0] = temp_ampm[0];
    	 temp_str_ampm[1] = temp_ampm[1];
    	 temp_str_ampm[2] = 0;

    ssd1306_WriteString(temp_str_ampm, Font_6x8, White);

    // Draw the clock hands based on the current time
    DrawClockHands(sTime.Hours, sTime.Minutes, sTime.Seconds);

    // Update the screen to show all changes
    ssd1306_UpdateScreen();
}

void Smart_Watch_Main()
{
    // Clear the screen and set it to black
    ssd1306_Fill(Black);


    ssd1306_SetCursor(21,25);
    ssd1306_WriteString(temp_time, Font_11x18, White);

    // Display the date on the screen
    ssd1306_SetCursor(1,1);
    ssd1306_WriteString(temp_date, Font_6x8, White);

    // Display the time buffer on the screen
    ssd1306_SetCursor(86,56);
    ssd1306_WriteString(temp_buffer, Font_6x8, White);

    // Display the day of the week on the screen
    ssd1306_SetCursor(74,1);
    ssd1306_WriteString(temp_day, Font_6x8, White);

    // Display AM or PM indicator on the screen
    ssd1306_SetCursor(1,56);
    ssd1306_WriteString(temp_ampm, Font_6x8, White);


    // Update the screen to show the changes
    ssd1306_UpdateScreen();
}




void Smart_Watch_Stop(char* temp_stop_watch)
{
    // Clear the screen and set it to black
    ssd1306_Fill(Black);

    ssd1306_SetCursor(1,1);
    ssd1306_WriteString(text_Stop_Watch, Font_7x10, White);

    ssd1306_SetCursor(20,27);
    ssd1306_WriteString(temp_stop_watch, Font_11x18, White);

    // Update the screen to show the changes
    ssd1306_UpdateScreen();
}

void Smart_Watch_Timer(char* temp_timer_watch)
{
    // Clear the screen and set it to black
    ssd1306_Fill(Black);

    ssd1306_SetCursor(1,1);
    ssd1306_WriteString(text_Timer, Font_7x10, White);

    ssd1306_SetCursor(20,27);
    ssd1306_WriteString(temp_timer_watch, Font_11x18, White);

    // Update the screen to show the changes
    ssd1306_UpdateScreen();
}


void Smart_Watch_Alarm(char* alarm_time)
{
    // Clear the screen and set it to black
    ssd1306_Fill(Black);

    ssd1306_SetCursor(1,1);
    ssd1306_WriteString(text_Alarm, Font_7x10, White);

    ssd1306_SetCursor(80,1);
    ssd1306_WriteString(temp_time, Font_6x8, White);

    ssd1306_SetCursor(36,28);
    ssd1306_WriteString(temp_alarm, Font_11x18, White);

    // Update the screen to show the changes
    ssd1306_UpdateScreen();
}

void updateWeekDay(void)
{
    // Increment the weekday index (1-7) and wrap around after Sunday
    sDate.WeekDay = (sDate.WeekDay % 7) + 1;

    // Set the updated date in the RTC
    HAL_RTC_SetDate(&hrtc, &sDate, RTC_FORMAT_BCD);

    // Update the day string with the new weekday
    sprintf(temp_day, "%s", weekDayStrings[sDate.WeekDay]);
}


void ToggleAMPM(void)
{
    // Toggle the AM/PM indicator
    currentAMPM = !currentAMPM;
}


//////////////////////////////////////// --Uart_callback--/////////////////////////////////////////////////



void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    if(huart->Instance == USART1)
    {
        HAL_UART_Receive_IT(&huart1, &tx, 1);

        Smart_Watch_Update(tx,temp_alarm,temp_stop_watch);
    }

    else if(huart->Instance == USART6)
    {
    	flag_basys = 1;

    	// basys -> stm : bcd -> binary change
    	for (int i=0; i<7; i++)
    	{
    		rx_basys[i] = (10 * (rx_basys[i] >> 4)) + (rx_basys[i] & 0x0f);
    	}

      	sprintf(temp_basys_date,"%2d/%2d/%2d",rx_basys[0],rx_basys[1],rx_basys[2]);  // Date
      	sprintf(temp_basys_time,"%2d:%2d:%2d",rx_basys[3],rx_basys[4],rx_basys[5]);  // Time

      	HAL_UART_Receive_IT(&huart6, rx_basys, 7);
    }



	else if(huart->Instance == USART2){


		if(rx=='\n'){
			buff[buffindex]=0;
			char *p;
			if((p=strstr((char*)buff,"SetClock")) != NULL){

				sTime.Hours = ((*(p+8)-'0') << 4) + (*(p+9)-'0');
				sTime.Minutes = ((*(p+10)-'0') << 4) + (*(p+11)-'0');
				sTime.Seconds = ((*(p+12)-'0') << 4) + (*(p+13)-'0');

				HAL_RTC_SetTime(&hrtc, &sTime, RTC_FORMAT_BCD);

			}else if((p=strstr((char*)buff,"SetDate")) != NULL){

				sDate.Year = ((*(p+7)-'0') << 4) + (*(p+8)-'0');
				sDate.Month = ((*(p+9)-'0') << 4) + (*(p+10)-'0');
				sDate.Date = ((*(p+11)-'0') << 4) + (*(p+12)-'0');

				HAL_RTC_SetDate(&hrtc, &sDate, RTC_FORMAT_BCD);
			}
			else if((p=strstr((char*)buff,"SetAlarm")) != NULL){

				sAlarm.AlarmTime.Hours = ((*(p+8)-'0') << 4) + (*(p+9)-'0');
				sAlarm.AlarmTime.Minutes = ((*(p+10)-'0') << 4) + (*(p+11)-'0');

				 HAL_RTC_SetAlarm_IT(&hrtc, &sAlarm, RTC_FORMAT_BCD);
			}
			else if ((p = strstr((char*)buff, "SetTimer")) != NULL) {


                timer_hour = ((*(p + 8) - '0') *10) + (*(p + 9) - '0');
                timer_minutes = ((*(p + 10) - '0') *10) + (*(p + 11) - '0');
                timer_seconds = ((*(p + 12) - '0') *10) + (*(p + 13) - '0');

                HAL_TIM_Base_Stop_IT(&htim5);

                sprintf(temp_timer_watch, "%02lu:%02lu:%02lu", timer_hour, timer_minutes, timer_seconds);
                Smart_Watch_Timer(temp_timer_watch);
            }

			else if (strstr((char*)buff, "NextDay") != NULL) {
			                updateWeekDay();
			}
			else if (strstr((char*)buff, "AM/PM") != NULL) {
							ToggleAMPM();
			}

			buffindex=0;
		}
		else{
			if(buffindex <30){
				buff[buffindex++]=rx;
			}
		}

		HAL_UART_Receive_IT(&huart2, &rx, 1);	// enable IT again
	}
}




//////////////////////////////////////// --Timer/Stop_watch--///////////////////////////////////////////////

void Stop_Watch_Start_Stop(uint8_t flag_stop_start_toggle)
{

	if(flag_stop_start_toggle == 0)	sw_start_stop = !sw_start_stop;
	else if (flag_stop_start_toggle == 1) sw_start_stop = 1;
	else if (flag_stop_start_toggle == 2) sw_start_stop = 0;

	if (sw_start_stop) {

        HAL_TIM_Base_Start_IT(&htim2);


    } else if(!sw_start_stop) {

        HAL_TIM_Base_Stop_IT(&htim2);
    }
	Smart_Watch_Stop(temp_stop_watch);
}


void Timer_Watch_Start_Stop(uint8_t flag_timer_start_toggle)
{
	if(flag_timer_start_toggle == 0)	timer_start_stop = !timer_start_stop;
	else if (flag_timer_start_toggle == 1) timer_start_stop = 1;
	else if (flag_timer_start_toggle == 2) timer_start_stop = 0;

	if (timer_start_stop) {

        HAL_TIM_Base_Start_IT(&htim5);


    } else if(!timer_start_stop) {

        HAL_TIM_Base_Stop_IT(&htim5);
    }
    Smart_Watch_Timer(temp_timer_watch);
}


void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
    if (htim->Instance == TIM2)
    {
        sw_milliseconds++;
        if (sw_milliseconds >= 100) {
            sw_milliseconds = 0;
            sw_seconds++;
            if (sw_seconds >= 60) {
                sw_seconds = 0;
                sw_minutes++;
            }

        }
        send_uart_sw = 1;
        sprintf(temp_stop_watch, "%02lu:%02lu:%02lu\n", sw_minutes, sw_seconds, sw_milliseconds);
        HAL_UART_Transmit(&huart2, (uint8_t*)temp_stop_watch, strlen(temp_stop_watch), 10);
    }


    if (htim->Instance == TIM5)
    {

        if (timer_seconds > 0) {
            timer_seconds--;
        } else {
            if (timer_minutes > 0) {
                timer_minutes--;
                timer_seconds = 59;
            } else {
                if (timer_hour > 0) {
                    timer_hour--;
                    timer_minutes = 59;
                    timer_seconds = 59;
                } else {

                	HAL_TIM_Base_Stop_IT(&htim5);
                    return;
                }
            }
        }


        sprintf(temp_timer_watch, "%02lu:%02lu:%02lu", timer_hour, timer_minutes, timer_seconds);
        Smart_Watch_Timer(temp_timer_watch);
    }



    if (htim->Instance == TIM4)
    {
  	  // RTC DATE/TIME Data

  	  HAL_RTC_GetTime(&hrtc, &sTime, RTC_FORMAT_BCD);
  	  HAL_RTC_GetDate(&hrtc, &sDate, RTC_FORMAT_BCD);
  	  HAL_RTC_SetAlarm_IT(&hrtc, &sAlarm, RTC_FORMAT_BCD);


   	  // Format the strings separately
  	  printf("\n");
  	  sprintf(temp_date, "%02x/%02x/%02x  ", sDate.Year, sDate.Month, sDate.Date);  // Date
  	  sprintf(temp_day, "%s  ", weekDayStrings[sDate.WeekDay]);  // Weekday
  	  sprintf(temp_ampm, "%s  ", ampm[currentAMPM]);
  	  sprintf(temp_time, "%02x:%02x:%02x \n", sTime.Hours, sTime.Minutes, sTime.Seconds);  // Time
  	  sprintf(temp_alarm, "%02x:%02x  ", sAlarm.AlarmTime.Hours, sAlarm.AlarmTime.Minutes);  // Time



  	  HAL_UART_Transmit(&huart2, (uint8_t*)temp_date, strlen(temp_date), 10);
  	  HAL_UART_Transmit(&huart2, (uint8_t*)temp_day, strlen(temp_day), 10);
  	  HAL_UART_Transmit(&huart2, (uint8_t*)temp_ampm, strlen(temp_ampm), 10);
  	  HAL_UART_Transmit(&huart2, (uint8_t*)temp_time, strlen(temp_time), 10);
  	  HAL_UART_Transmit(&huart2, (uint8_t*)temp_alarm, strlen(temp_alarm), 10);

  	  /////////////////////////////////////////////////////////////////////////////////////////////////////

	  stm32_bcd_data[0] = sDate.Year;
	  stm32_bcd_data[1] = sDate.Month;
	  stm32_bcd_data[2] = sDate.Date;
	  stm32_bcd_data[3] = sTime.Hours;
	  stm32_bcd_data[4] = sTime.Minutes;
	  stm32_bcd_data[5] = sTime.Seconds;
	  stm32_bcd_data[6] = 2;


	  rx_basys[5]++;
      if (rx_basys[5] >= 60) {
    	  rx_basys[5] = 0;
    	  rx_basys[4]++;
          if (rx_basys[4] >= 60) {
        	  rx_basys[4] = 0;
        	  rx_basys[3]++;
          }
      }


	  sprintf(temp_basys_date,"%02d/%02d/%02d",rx_basys[0],rx_basys[1],rx_basys[2]);  // Date
      sprintf(temp_basys_time,"%02d:%02d:%02d",rx_basys[3],rx_basys[4],rx_basys[5]);  // Time

	  HAL_UART_Receive_IT(&huart6, rx_basys, 7);
	  HAL_UART_Transmit_IT(&huart2, rx_basys, 7);


/*
 	 if(flag_basys)
	  {
		  if(basys_count > 3)
		  {
			  flag_basys = 0;
			  basys_count = 0;
		  }
		  else basys_count++;
	  }
*/

  	  /////////////////////////////////////////////////////////////////////////////////////////////////////

  	  // ultrasonic

  	  HCSR04_read();
  	  printf("\ndistance : %3d\r\n", distance);

  	  //////////////////////////////////////////////////////////////////////////////////////////////////////

  	  // dht11

  	  if(dht11_read() == 1) {
  		  sprintf((char *)temp_buffer, "%dC %d%%\n", Temperature, Humidity);
  		  HAL_UART_Transmit(&huart2, temp_buffer, strlen((char *)temp_buffer), 100);
  	  }

  	  /*
  	  else {
  		  sprintf((char *)temp_buffer, "timeout\n");
  		  HAL_UART_Transmit(&huart2, temp_buffer, strlen((char *)temp_buffer), 100);
  	  }
  	  */
    }
}






////////////////////////////////////////////////////////////////////////////////////////////////



/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */



  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_RTC_Init();
  MX_USART2_UART_Init();
  MX_SPI1_Init();
  MX_TIM3_Init();
  MX_TIM11_Init();
  MX_TIM1_Init();
  MX_USART6_UART_Init();
  MX_TIM2_Init();
  MX_TIM4_Init();
  MX_TIM5_Init();
  MX_USART1_UART_Init();
  /* USER CODE BEGIN 2 */

  HAL_UART_Receive_IT(&huart1, &tx, 1);
  HAL_UART_Receive_IT(&huart2, &rx, 1);

  ssd1306_Init();

  HAL_TIM_Base_Start(&htim11);	// for delay func
  HAL_TIM_IC_Start_IT(&htim3, TIM_CHANNEL_1);	// for ultrasonic

  HAL_TIM_Base_Start(&htim1);  // delay_ms()
  HAL_TIM_Base_Start_IT(&htim4);


  // sAlarm.AlarmTime.Seconds;
  sAlarm.AlarmMask = RTC_ALARMMASK_DATEWEEKDAY|RTC_ALARMMASK_SECONDS;
  sAlarm.Alarm = RTC_ALARM_A;

  //HAL_UART_DeInit(&huart6);



  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {

	  Smart_Watch_Lcd_Refresh();

/*
 	  stm32_bcd_data[0] = sDate.Year;
	  stm32_bcd_data[1] = sDate.Month;
	  stm32_bcd_data[2] = sDate.Date;
	  stm32_bcd_data[3] = sTime.Hours;
	  stm32_bcd_data[4] = sTime.Minutes;
	  stm32_bcd_data[5] = sTime.Seconds;
	  stm32_bcd_data[6] = 0;

	  HAL_UART_Transmit(&huart6, (uint8_t*)stm32_bcd_data, sizeof(stm32_bcd_data), 10);
	  HAL_UART_Transmit(&huart2, (uint8_t*)stm32_bcd_data, sizeof(stm32_bcd_data), 10);

	  HAL_Delay(1000);
*/



    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE|RCC_OSCILLATORTYPE_LSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.LSEState = RCC_LSE_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLM = 4;
  RCC_OscInitStruct.PLL.PLLN = 100;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_3) != HAL_OK)
  {
    Error_Handler();
  }
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
