
#include "alarm.h"

uint8_t alarm_active = 1;

void Alarm_On_Off()
{
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_10, RESET);
	alarm_active = !alarm_active;
}


void HAL_RTC_AlarmAEventCallback(RTC_HandleTypeDef *hrtc)
{
	if (alarm_active)
	{
		HAL_GPIO_TogglePin(GPIOA, GPIO_PIN_10);
		const char *alarm_message = "alarm!!!\n";
		HAL_UART_Transmit(&huart2, (uint8_t *)alarm_message, strlen(alarm_message), HAL_MAX_DELAY);
	}
}
