
#include "ultrasonic.h"


uint16_t IC_VALUE1      = 0;
uint16_t IC_VALUE2      = 0;
uint16_t echoTime       = 0;
uint16_t captureFlag    = 0;
uint16_t distance       = 0;


void HAL_TIM_IC_CaptureCallback(TIM_HandleTypeDef *htim)
{
    // Check if the interrupt is triggered by the correct timer channel
    if(htim->Channel == HAL_TIM_ACTIVE_CHANNEL_1)
    {
        // If this is the first capture (rising edge)
        if(captureFlag == 0)
        {
            // Capture the value at the rising edge
            IC_VALUE1 = HAL_TIM_ReadCapturedValue(&htim3, TIM_CHANNEL_1);
            captureFlag = 1;

            // Set the polarity to detect the falling edge next
            __HAL_TIM_SET_CAPTUREPOLARITY(&htim3, TIM_CHANNEL_1, TIM_INPUTCHANNELPOLARITY_FALLING);
        }
        // If this is the second capture (falling edge)
        else if(captureFlag == 1)
        {
            // Capture the value at the falling edge
            IC_VALUE2 = HAL_TIM_ReadCapturedValue(&htim3, TIM_CHANNEL_1);

            // Reset the timer counter
            __HAL_TIM_SET_COUNTER(&htim3, 0);

            // Calculate the time difference between the rising and falling edge captures
            if(IC_VALUE2 > IC_VALUE1)
            {
                echoTime = IC_VALUE2 - IC_VALUE1;
            }
            else if(IC_VALUE1 > IC_VALUE2)
            {
                echoTime = (0xffff - IC_VALUE1) + IC_VALUE2;
            }

            // Calculate the distance based on the echo time
            distance = echoTime / 58;

            // Reset the capture flag for the next measurement
            captureFlag = 0;

            // Set the polarity back to detect the next rising edge
            __HAL_TIM_SET_CAPTUREPOLARITY(&htim3, TIM_CHANNEL_1, TIM_INPUTCHANNELPOLARITY_RISING);

            // Disable the capture interrupt until the next trigger
            __HAL_TIM_DISABLE_IT(&htim3, TIM_IT_CC1);
        }
    }
}

void HCSR04_read()
{
    // Trigger the ultrasonic sensor by setting the TRIG pin high
    HAL_GPIO_WritePin(TRIG_PORT, TRIG_PIN, 1);

    // Wait for 10 microseconds
    delay_us(10);

    // Set the TRIG pin low to complete the trigger pulse
    HAL_GPIO_WritePin(TRIG_PORT, TRIG_PIN, 0);

    // Enable the capture interrupt to start listening for the echo response
    __HAL_TIM_ENABLE_IT(&htim3, TIM_IT_CC1);
}
