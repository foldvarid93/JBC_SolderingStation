# JBC Soldering Station 

This project was created to help people who would use a C245 and C470 JBC handle and cartridge without the expensive controller. 
There is some project on the internet what provides a solution. My first steps was also to find a complete method or solution.
Here is some already existing projects.

-Marco Reps: https://drive.google.com/file/d/0B6S_PcWWM1YlY1lORkhDcTAzdEU/view 

-Great Scot: https://www.instructables.com/id/DIY-Arduino-Soldering-Station/

-sparkybg: http://dangerousprototypes.com/forum/index.php?topic=7218.0#p61175

## There are some basic problems with those solution:

-I don't have an arduino and I don't want to use that. 

-I wanted to use PID control to provide stable temperature at the end of the tip. 

-I wanted to use LCD display that I have bought a long-long time ago. 

-I wanted to build the HW with components that I already had.

-I would implemented the sleep function.

-3D printed housing with individual design. 

-Individual PCB design.

-I wanted an encoder as user input.

-I wanted to use SPI thermocouple interface IC. 

So, to sum up the above mentioned point there is no universal solution. Okay, Unisolder would be the best choice, but I only want a JBC 470 compatible contoller. I can't flash PICs, and the schematic is overcomplicated.(Nevertheless, I know that is an UNIversal SOLution for any types of solDERing irons...)
So I have decided that I will create my own project. The main goal was to create a good and cheap alternative, and during the prototyping I would have to learnt (PID, programming, signal processing, a little power electronics, Matlab, etc).   

## 1 First steps

### 1.1 The JBC cartridges 

Firstly I wanted to build a proper working proto HW. On the net, there are a lots of true and false informations about the cartridge. There are 2 type of people: The first typed are saying the common conductor is the red wire, and the second says green. Okay but what is the truth?

![1](https://user-images.githubusercontent.com/41072101/65080289-3bef2080-d9a1-11e9-89b8-67e0d76b42ab.jpg)

There was a person who mentioned on some electronics forum that the green is the common conductor, this is the outer sleeve of the cartridge what is supposed to be grounded (ESD safety). And there are a lots of people who says the common conductor is the pin (the end of the tip). At that point i was absolutely confused...

[I found an article on the web about these JBC cartridges.](https://patents.google.com/patent/EP1086772A2/en) According to that document the heating element is between red(common, heater1 and TC+)[2] and blue(heater2)[5] and the thermocouple is between red(heater1 and TC+)[2] and green(TC-)[1]. *[Connector pin number on the soldering iron] To make this statement absolutely true, I have performed some basic measurements on the tip. 
1. The heater is around 2-3Ohm sightly depending on the ambient temperature. For me that was ~2,5Ohm.
2. According to the sketch above, I heated up the tip with an external heat source (cigarette lighter, another soldering iron). When the tip is around 2-300°C the thermocouple generates 4-6mV. Measuring DC voltage between red and green with a multimeter, you need to see something like that values.

![image](https://user-images.githubusercontent.com/41072101/73572543-58cc5200-4471-11ea-97a1-d64d471245e8.png)

When you measure at 2-300°C between blue and green (heater2 and TC-) you can measure the series resistance of the TC and heater coil. When you put the positive cable on the blue and the negative on the green you need to measure higher(?) value compared with the reversed measurement (positive on the green and negative on the blue). If the difference is recognizable and we can be sure about that is not a measuring error, we can state that the first supposition is the reality.
When you are skeptic about the right consequences you can repeat the measurements with the second theorem (I did)...

### 1.2 Ideas -> Paper sketches

## 2 Designing HW prototype.

### 2.1 The used components and the experimental schematic

![2](https://user-images.githubusercontent.com/41072101/65081428-eb2cf700-d9a3-11e9-91fd-5e8b2c111bff.JPG)

I only use AVRs and STM32s, so there wasn't a question what I will use. To contolling the LCD with a proper refresh rate STM32's computing performance was requred. The proto board was built around an STM32L476-Nucleo board.
The MCU is responsible for contolling the LCD, computing PID, reading TC via SPI, swithing on and off the sleep function, handling the encoder. The timing is provided by a zero crossing detector.    

### 2.2 Zero crossing detection

![3](https://user-images.githubusercontent.com/41072101/65081750-a6ee2680-d9a4-11e9-814c-e4791172c209.png)
![4](https://user-images.githubusercontent.com/41072101/65081762-ab1a4400-d9a4-11e9-85f3-1844e0a76e47.jpg)

To aid my work I used TINA simulation to design a zero-crossing detector. This is a fedbacked comparator what provides rising and falling edges. The isolated DCDC converter and the optotransistor provides the galvanical isoaltion from the other parts of the schematic. A full-bridge rectifier make the sine wave to be only above the zero. The comparator sets its output according to the its imputs. If the negative input is higher the output will be 'GND' or local negative potential, and if the positive input is higher the output will be on local +VCC (~32V). The other side of the optotransistor there is an open collector output that goes to an interrupt input what is pulled up internally to the MCU +VCC potential(3,3V).

Note: This logic is reversed the original signal, but we can handle it from the sw.

The theorem is the following:

We work in 11 half waves cycles. One of them is for reading out the TC temperature data. Until the reading we need to switch off the power on the heating element because currents on the common wire can easily influence the TC's ultra sensitive signal. The first half wave of the 11 is only for the temperaure reading. After the reading(s) from the second half wave to the eleventh we can control the half waves according to the PID. We need to normalize the output "duty" to 10% steps, because we have 10 half wave and we only can switch on for integer halfwaves. So the duty is can be calculated by ONhw/11 where ONhw is the half waves when the output is ON and it goes from 0 to 10. So the effective duty is minumum 0%(obviously) and the maximum is 90%. Nevertheless, don't worry, this soldering iron can be heated up from room temperature to red glowing within 15 seconds if you are not careful with 3/11 duty. I wasn't careful enough... :(     

### 2.3 The power stage

In the original solution there are 2 serially connected MOSFET. To save money I designed my DIY station with triac. It can be used in both half period of the sinusoidal curve.    

![6](https://user-images.githubusercontent.com/41072101/65175396-1ae70800-da53-11e9-9e33-f825b67ad4df.png)

The switching circuit for the heating element contains an optotriac to isolate the AC power from the MCU power supply. My transformer can produce 9A current with 24V voltage and a C245 type cartridge can consumpt 130-150W during the heating up sequence. I used a typical circuit for the AC part. Fortunately there is no demand for a more complex solution. I chosed a MOC3041 optotriac with internal zero-cross detector. My plan was that I use my individual "zero-cross detector" to generate external interrupts for the MCU at every 10ms. I use the rising and falling edges to find out where the sine wave is at a certain point. Before the zero crossing, the interrupt can switch off the optotriac's LED and at the next halfwave triac will remain in off-state. In that case when thermocouple need to be read but first of all the software must wait some 100us or 1ms after the zero point to be sure the switching transients had eliminated.         

### 2.4 Thermocouple interface circuit (EXPERIMENTAL)

To get some experience with an interface IC, I tried the MAX31855 thermocouple IC.  

![5](https://user-images.githubusercontent.com/41072101/65082635-b8383280-d9a6-11e9-8926-9a84499579d3.png)

At this point there was an uncertain part of the whole project. Except the manufacturer maybe noone knows the exact type of the thermocouple in the cartridge. On the market there are available thermocouple interface IC-s from Maxim Integrated. I ordered [MAX31855](https://datasheets.maximintegrated.com/en/ds/MAX31855.pdf) IC N and K type to try out both. First of all I tried the N type. There is an additional thing about this. You can not use grounded thermocouple, so you need to find a solution because the outer sleeve of the C245 cartridge is ESD grounded via 1MOhm resistor (the tip might be ESD safe in a good soldering iron). So I needed to isolate the 5V (and 3,3V) power supply of the MCU from the ground and from the heater circuits.

The result of the experiment: This is not a proper solution to reading temperature values. The main problem is the timing. This interface IC can communicate with the MCU over SPI but the measurements cannot be performed at that point. In the background the IC refresh its registers with the actual (Okay, what is the actual? When? And where? At the top of the sinewave? Yes maybe there, maybe at the middle of the sine, so it is not deterministic...)

![image](https://user-images.githubusercontent.com/41072101/73133221-e51be680-4025-11ea-9432-029fad706f45.png)

It can be seen, the Temperature conversion time has a massive jitter. 70 to 100ms (5 period of the line sine wave(50Hz)). In this range a specific IC can be anywhere, so we can't hold the precise timings.

### 2.6 Thermocouple interface with a precision opamp (The final solution)

What is the precison opamp? And what precison we need to perform here? In this case we have N x 10uV voltage on the thermocouple sensor. At 500°C temperature the sensor gives 10-20mV signal. We have 12bit, 3.3V ADC in the STM32. This means 4096 unit in 3.3V range. One unit is 3.3V/4096=0,0008056640625 => 0.8056640625mV =>805.6640625uV. We have 26uV Siebeck-coefficient, so the error would be 805.6640625uV/26uV/°C=31°C. This is why we need to condition the thermocouple's signal. 
There is 2 important requirements with the opamp
-The noise on the output need to be as small as possible
-The offset voltage and current need to be as small as possible (~0)
-Singe rail capability (we only have 3.3V MCU supply)
-Rail to rail output (output linearity near the positive and negative supply potential)

My choice was the [Texas Instruments OPA335](https://www.ti.com/lit/ds/symlink/opa335.pdf).  

### 2.7 Optical isolations

Because this soldering station designed for a single 24V AC supply the power stage and the 5V MCU supply need to be separated from each other. Only one point can be common on. This is the GND. The triac is driven by an optotriac. Because the zero crossing detector uses a rectified 24V(eff) power supply what is around 32VDC, it need to be separated from the MCU pin which is 5V tolerant but normally 3.3V.
The MCU supply is galvanically separated from the rectified and puffered input supply with an isolated Murata DC-DC converter.

### 2.8 The complete schematic drawing
To sum it up, here is the whole schematic drawing according to above mentioned points. 
You can see that I used a precision amplifier instead of a thermocouple interface IC. 
![2020-01-26_10h13_12](https://user-images.githubusercontent.com/41072101/73133107-8ace5600-4024-11ea-8c63-d67544de25a5.png)

### 2.9 PCB design
Individual PCB was designed in Altium Designer software. The size of the board is 100x55mm. I always design with 3D components, because later I design a housing for my devices, it can be a big help if I have a precise 3D model of my PCBs. 

![2019-11-19_20h41_34](https://user-images.githubusercontent.com/41072101/69180168-22876380-0b0d-11ea-893a-51111d1dae46.png)
![2019-11-19_20h41_43](https://user-images.githubusercontent.com/41072101/69180170-22876380-0b0d-11ea-9e77-9504e61e7dab.png)
![2019-11-19_20h42_02](https://user-images.githubusercontent.com/41072101/69180171-231ffa00-0b0d-11ea-8d08-4d8cdb8b5fda.png)
![2019-11-19_20h42_17](https://user-images.githubusercontent.com/41072101/69180172-231ffa00-0b0d-11ea-9ee3-e3be4d7f2462.png)

### 2.10 Prototype PCB
My ptototype PCB's were made by [JLCPCB](https://jlcpcb.com) in China. I am not recommend to make PCB at home (toxic acids, vapours that can harmful for you), okay, to deliver 5 PCB with airplane not so environmentally friendly too... I left the choice for everyone. :)
I ordered my boards with 6 days shipping. The total cost is around 25$, but it can be less if you can wait 15-20 working days for the delivery.

![IMG_2302](https://user-images.githubusercontent.com/41072101/73133544-683f3b80-402a-11ea-9fcb-9eb59c408e8d.JPG)
![IMG_2303](https://user-images.githubusercontent.com/41072101/73133545-68d7d200-402a-11ea-8ddb-eb43cb129a42.JPG)

I ordered all of components from RS Components (some components from other local stores near my home). The component BOM can be found here.
### 2.11 Final PCB assembly 

![IMG_0224](https://user-images.githubusercontent.com/41072101/73133752-72af0480-402d-11ea-94ba-533ad89b242f.JPG)
![IMG_0222](https://user-images.githubusercontent.com/41072101/73133753-72af0480-402d-11ea-8fea-0b1f20697ce8.JPG)
![IMG_0223](https://user-images.githubusercontent.com/41072101/73133754-73479b00-402d-11ea-94b9-662fef70e5ec.JPG)

## 4 Software

### 4.1 Software overview

### 4.2 PID control loop

Just to give you a full overview to the PID, I will share my experiences with different methods.
#### 4.2.1 Discrete PID 

### 4.3 User Interface

I used the free STemWin GUI library to give a simple graphic user interface for this project. As in my other projects also in this was used an inexpensive 240x320 pixel LCD module from ebay. To avoid problems I used my own low level driver for this Arduino typed LCD module.

![IMG_1645](https://user-images.githubusercontent.com/41072101/64068853-74bb9580-cc3e-11e9-9b0a-3bea928fe507.JPG)

### 4.4 Final software

[The software can be found here.](https://github.com/foldvarid93/JBC_SolderingStation/tree/master/Software)

### 4.5 Tests and validations 

## 5 Housing design, 3D printing

## 6 Build up

## 7 Tests, conclusions

## 8 Additinal informations

## 9 Some picture about the station

![IMG_1646](https://user-images.githubusercontent.com/41072101/64068854-75542c00-cc3e-11e9-8e9e-f17c2271b396.JPG)
![IMG_1636](https://user-images.githubusercontent.com/41072101/64068855-7a18e000-cc3e-11e9-8ed5-411b4704acae.JPG)
![IMG_1635](https://user-images.githubusercontent.com/41072101/64068856-7be2a380-cc3e-11e9-801f-e3c6e9291d29.JPG)
