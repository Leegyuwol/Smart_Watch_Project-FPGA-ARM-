
#include "dht11.h"


int Temperature = 0;
int Humidity = 0;
uint8_t temp_buffer[256];


void dht11_delay_us(uint16_t time) {
    // Delay for a specified number of microseconds using TIM1
    __HAL_TIM_SET_COUNTER(&htim1, 0);
    while((__HAL_TIM_GET_COUNTER(&htim1)) < time);
}

int wait_pulse(int state) {
    // Wait for the GPIO pin to reach the desired state (HIGH or LOW) within 100us.
    // Returns 1 if the state is achieved, 0 if a timeout occurs.
    __HAL_TIM_SET_COUNTER(&htim1, 0);
    while (HAL_GPIO_ReadPin(DHT11_PORT, DHT11_PIN) != state) {
        if(__HAL_TIM_GET_COUNTER(&htim1) >= 100) {
            return 0; // Timeout
        }
    }
    return 1; // Success
}

int dht11_read(void) {
    //----- Start Signal
    // Configure GPIO pin as output to send start signal to DHT11
    GPIO_InitTypeDef GPIO_InitStruct = {0};
    GPIO_InitStruct.Pin = DHT11_PIN;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(DHT11_PORT, &GPIO_InitStruct);

    // Send start signal: Low for 18ms, then High for 20us
    HAL_GPIO_WritePin(DHT11_PORT, DHT11_PIN, 0);
    dht11_delay_us(18000);
    HAL_GPIO_WritePin(DHT11_PORT, DHT11_PIN, 1);
    dht11_delay_us(20);

    // Configure GPIO pin as input to receive data from DHT11
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(DHT11_PORT, &GPIO_InitStruct);

    dht11_delay_us(40);  // Wait for 40us to check the response from DHT11
    if (!(HAL_GPIO_ReadPin(DHT11_PORT, DHT11_PIN))) {   // Check if DHT11 pulled the line low
        dht11_delay_us(80);
        if (!(HAL_GPIO_ReadPin(DHT11_PORT, DHT11_PIN))) // DHT11 should pull the line high after 80us
            return -1; // If not, return error
    }
    if (wait_pulse(GPIO_PIN_RESET) == 0) // Wait for the response signal from DHT11
        return -1; // Timeout

    //----- Read Data from DHT11
    uint8_t out[5], i, j;
    for(i = 0; i < 5; i++) {  // Loop to read 5 bytes of data (Humidity, Temperature, and Checksum)
        for(j = 0; j < 8; j++) {  // Loop to read each bit (8 bits in each byte)
            if(!wait_pulse(GPIO_PIN_SET))  // Wait for the data bit to be sent
                return -1;

            dht11_delay_us(40);  // Wait for the bit to be valid
            if(!(HAL_GPIO_ReadPin(DHT11_PORT, DHT11_PIN)))
                out[i] &= ~(1<<(7-j));  // If the pin is low, bit is 0
            else
                out[i] |= (1<<(7-j));   // If the pin is high, bit is 1

            if(!wait_pulse(GPIO_PIN_RESET))  // Wait for the next bit
                return -1;
        }
    }

    // Verify checksum
    if(out[4] != (out[0] + out[1] + out[2] + out[3]))
        return -2; // Checksum mismatch

    Temperature = out[2];
    Humidity = out[0];

    return 1; // Success
}
