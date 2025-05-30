--[[
******************************************************************************************
******************Cessna Citation CJ4 Trim and Engine Control Panel*******************
******************************************************************************************

    Made by SIMSTRUMENTATION "EXTERMINATE THE MICE FROM YOUR COCKPIT!"
    GitHub: http://simstrumentation.com


- **v1.0** 03-13-2021 Rob "FlightLevelRob" Verdon
    - Original Panel Created
- **v1.1** 08-02-2021 Joe "Crunchmeister" Gilker
   - Fixed start functionality that had been broken by a previous update  
- **v2.0** 09-17-2021 Joe "Crunchmeister" Gilker and Todd "Toddimus831" Lorey
   - New custom graphics
   - Functional covers added to run buttons. Touch or click the cover hinges to open and close.
              Run switches will be INOP until covers are open.
   - Slight tweaks to PIC_EngineX_ and PIC_StarterX positions to center them better in their buttons
   - Refactored code to adapt to native A: variable and K: events and remove MobiFlight dependency
--*********END OF INTERNAL ALPHA TESTING****************
- **v2.0** 10-5-2021 Rob "FlightLevelRob" Verdon and Joe "Crunchmeister" Gilker and Todd "Toddimus831" Lorey
    !!- Initial Public Release -!!
    - Variable renaming for clarity
    - Added backlight logic to account for battery, external power and bus volts status
- **v2.1** 01-16-2022
    - Sounds replaced with custom.
    - Resource folder file capitials renamed for SI Store submittion  
- **v2.2** 12-06-2022 Joe "Crunchmeister" Gilker       
   - Updated code to reflect AAU1 being released in 2023Q1
   
## Left To Do:
  - Secondary Elev Trim is inop.

## Notes:
  - Protective covers on RUN buttons functional. Touch or click the cover hinges to open and close. Run switches will be INOP until covers are open.

******************************************************************************************
--]]
  
--Backgroud Image before anything else
img_add_fullscreen("background.png")
img_bg_night = img_add_fullscreen("bg_night.png")

img_labels_backlight = img_add_fullscreen("labels_backlight.png ")

function ss_ambient_darkness(value)
    opacity(img_bg_night, value, "LOG", 0.04)    --set this panels night background 
    if value < 0.7 then
       dimval = 1-value
    else
        dimval = 0.3
    end
    if value > 0.25 and value <= 1.0 then
        opacity(img_L_Closed,dimval, "LOG", 0.04) 
        opacity(img_R_Closed,dimval, "LOG", 0.04)
        opacity(img_L_Open,dimval, "LOG", 0.04) 
        opacity(img_R_Open,dimval, "LOG", 0.04)   
        opacity(Elev_Trim_Knob,dimval, "LOG", 0.04)   
        opacity(Rudder_Trim_Knob,dimval, "LOG", 0.04)   
        opacity(AILERON_Trim_Knob,dimval, "LOG", 0.04)   
    else 
        opacity(img_L_Closed, 1.0, "LOG", 0.04)
        opacity(img_R_Closed,1.0, "LOG", 0.04)
        opacity(img_L_Open,1.0, "LOG", 0.04) 
        opacity(img_R_Open,1.0, "LOG", 0.04)
        opacity(Elev_Trim_Knob,1.0, "LOG", 0.04)   
        opacity(Rudder_Trim_Knob,1.0, "LOG", 0.04)  
        opacity(AILERON_Trim_Knob,1.0, "LOG", 0.04)  
    end 
end
si_variable_subscribe("sivar_ambient_darkness", "FLOAT", ss_ambient_darkness)

function ss_backlighting(value, panellight, power, extpower, busvolts)
    value = var_round(value,2)      
    if  panellight == false  or (power == false and extpower == false and busvolts < 5) then 
        opacity(img_labels_backlight, 0.1, "LOG", 0.04)
        opacity(img_rudder_knob_indicator_backlight, 0.0, "LOG", 0.04)
    else
        opacity(img_labels_backlight, ((value/2)+0.5), "LOG", 0.04)
        opacity(img_rudder_knob_indicator_backlight, ((value/2)+0.5), "LOG", 0.04)
    end
end
fs2020_variable_subscribe("A:LIGHT POTENTIOMETER:3", "Number",
                           "LIGHT PANEL","Bool",
                          "ELECTRICAL MASTER BATTERY","Bool",
                          "EXTERNAL POWER ON:1", "Bool",
                          "ELECTRICAL MAIN BUS VOLTAGE", "Volts", ss_backlighting)
						  
local  left_run = 0
local right_run = 0


PIC_Engine1_Run = img_add( "Engine_Run.png", 158,33,90,70)
PIC_Engine1_Stop = img_add("Engine_Stop.png", 169,69,70,50)


PIC_Engine2_Run = img_add("Engine_Run.png", 422,33,90,70)
PIC_Engine2_Stop = img_add("Engine_Stop.png", 433,69,70,50)
visible(PIC_Engine1_Run, false)
visible(PIC_Engine2_Run, false)
visible(PIC_Engine1_Stop, false)
visible(PIC_Engine2_Stop, false)


PIC_Starter1_On = img_add("LTS_On.png", 205,258,50,10)
PIC_Starter2_On = img_add("LTS_On.png", 410,258,50,10)
visible(PIC_Starter1_On, false)
visible(PIC_Starter2_On, false)

Rudder_Trim_Knob = img_add("RudderTrim_Knob.png", 180,668,125,125)
rotate(Rudder_Trim_Knob, 0, "LOG", 0.04)
img_rudder_knob_indicator_backlight = img_add("RudderTrim_Knob_indicator.png", 180,668,125,125)
rotate(img_rudder_knob_indicator_backlight, 0, "LOG", 0.04)

Elev_Trim_Knob = img_add("Elev_Trim.png", 425,395,95,127)
visible(Elev_Trim_Knob, true)
move(Elev_Trim_Knob, nil, nil, nil, nil, "LOG", 0.04)

AILERON_Trim_Knob = img_add("Aileron_Trim.png", 135,400,127,95)
visible(AILERON_Trim_Knob, true)
move(AILERON_Trim_Knob, nil, nil, nil, nil, "LOG", 0.04)

---Sounds
click_snd = sound_add("click.wav")
fail_snd = sound_add("beepfail.wav")
cover_open_snd = sound_add("cover_open.wav")
cover_close_snd = sound_add("cover_close.wav")

--Locals
local L_Starter1_Status = false
local L_Starter2_Status = false
local L_Mix1_Status = false 
local L_Mix2_Status = false
local L_Fuel_Valve1_Status = false
local L_Fuel_Valve2_Status = false
local L_Ign_Switch1_Status = false
local L_Ign_Switch2_Status = false
local L_Battery_Master_Status = false
local L_External_Power_Status = false
local L_Bus_Volts = 0

--------ENGINES---  Determine and set variable states and visibilities
function ss_Engine_Status( Starter1_Status, Starter2_Status, 
			Mix1_Status, Mix2_Status,
			Fuel_Valve1_Status, Fuel_Valve2_Status,
			Ign_Switch1_Status, Ign_Switch2_Status,
			Battery_Status, ExtPwr_Status, Bus_Volts)
	--BATTERY
		L_Battery_Master_Status = Battery_Status

	--EXTERNAL POWER
		L_External_Power_Status = ExtPwr_Status

	--BUS VOLTS
		L_Bus_Volts = Bus_Volts

	--STARTER1
		if Starter1_Status == true and (L_Battery_Master_Status == true or L_External_Power_Status == true or L_Bus_Volts > 5) then 
			visible(PIC_Starter1_On, true)
			L_Starter1_Status = true
		else 
			visible(PIC_Starter1_On, false)
			L_Starter1_Status = false        
		end 

	--STARTER2
		if Starter2_Status == true and (L_Battery_Master_Status == true or L_External_Power_Status == true or L_Bus_Volts > 5) then 
			visible(PIC_Starter2_On, true)
			L_Starter2_Status = true        
		else 
			visible(PIC_Starter2_On, false)
			L_Starter2_Status = false        
		end 

	--MIXTURES -- For determining run/stop status
		if Mix1_Status > 0 then
			L_Mix1_Status = true
		else
			L_Mix1_Status = false
		end
		if Mix2_Status > 0 then
			L_Mix2_Status = true
		else
			L_Mix2_Status = false
		end

	--FUEL VALVES -- For determining run/stop status
		L_Fuel_Valve1_Status = Fuel_Valve1_Status
		L_Fuel_Valve2_Status = Fuel_Valve2_Status

	--IGNITION SWITCHES (NOT MANUAL IGNITION) -- For determining run/stop status
		if Ign_Switch1_Status == 0 then
			L_Ign_Switch1_Status = false
		else
			L_Ign_Switch1_Status = true
		end
		if Ign_Switch2_Status == 0 then
			L_Ign_Switch2_Status = false
		else
			L_Ign_Switch2_Status = true
		end

	--SET RUN/STOP STATUS
		if (L_Battery_Master_Status == true or L_External_Power_Status == true or L_Bus_Volts > 5) then  --Battery is On	
			if (L_Starter1_Status == true or L_Starter2_Status == true) and L_Mix1_Status == false and L_Mix2_Status == false then
				visible(PIC_Engine1_Run, false)
				visible(PIC_Engine1_Stop, false) 
				visible(PIC_Engine2_Run, false)
				visible(PIC_Engine2_Stop, false)      
			else		
			--Engine 1
				if L_Starter1_Status == false then
					if L_Mix1_Status == true  then 
						visible(PIC_Engine1_Run, true)
						visible(PIC_Engine1_Stop, false)
					elseif L_Mix1_Status == false then
						visible(PIC_Engine1_Run, false)
						visible(PIC_Engine1_Stop, true)         
					end 
				else --turn off when starter is on
					if L_Mix1_Status == true  then 
						visible(PIC_Engine1_Run, true)
						visible(PIC_Engine1_Stop, false)
					elseif L_Mix1_Status == false  then 
						visible(PIC_Engine1_Run, false)
						visible(PIC_Engine1_Stop, false)                 
					end
				end				
			--Engine 2
				if L_Starter2_Status == false then
					if L_Mix2_Status == true  then 
						visible(PIC_Engine2_Run, true)
						visible(PIC_Engine2_Stop, false)
					elseif L_Mix2_Status == false then
						visible(PIC_Engine2_Run, false)
						visible(PIC_Engine2_Stop, true)         
					end 
				else --turn off when starter is on
					if L_Mix2_Status == true  then 
						visible(PIC_Engine2_Run, true)
						visible(PIC_Engine2_Stop, false) 
					elseif L_Mix2_Status == false  then 
						visible(PIC_Engine2_Run, false)
						visible(PIC_Engine2_Stop, false)                 
					end
				end    
			end
			if L_Fuel_Valve1_Status == false and L_Mix1_Status == false and L_Starter2_Status == true then -- this is weird but it's what the sim does
						visible(PIC_Engine1_Run, false)
						visible(PIC_Engine1_Stop, false)
			end	     
			if L_Fuel_Valve2_Status == false and L_Mix2_Status == false and L_Starter1_Status == true then -- this is weird but it's what the sim does
						visible(PIC_Engine2_Run, false)
						visible(PIC_Engine2_Stop, false)
			end	     		
		else --Battery is Off
			visible(PIC_Engine1_Run, false)
			visible(PIC_Engine1_Stop, false) 
			visible(PIC_Engine2_Run, false)
			visible(PIC_Engine2_Stop, false)        
		end
end

fs2020_variable_subscribe("GENERAL ENG STARTER:1","Bool",  
                          "GENERAL ENG STARTER:2","Bool",
                          "GENERAL ENG MIXTURE LEVER POSITION:1", "Percent",  
                          "GENERAL ENG MIXTURE LEVER POSITION:2", "Percent",  
                          "GENERAL ENG FUEL VALVE:1", "Bool",
                          "GENERAL ENG FUEL VALVE:2", "Bool",
                          "TURB ENG IGNITION SWITCH EX1:1", "enum",
                          "TURB ENG IGNITION SWITCH EX1:2", "enum",
                          "ELECTRICAL MASTER BATTERY","Bool",
                          "EXTERNAL POWER ON:1", "Bool",
                          "ELECTRICAL MAIN BUS VOLTAGE", "Volts", ss_Engine_Status)

--ENGINE 1
function callback_Engine1_Run_Toggle()
    if left_run == 0 then    --if button cover is down, play fail sound and don't start the engine
		sound_play(fail_snd)
    else    -- run toggle logic if cover is open
		if  (L_Battery_Master_Status == true or L_External_Power_Status == true or L_Bus_Volts > 5) then
			if L_Mix1_Status == true then
				fs2020_event("MIXTURE1_LEAN")
				if L_Fuel_Valve1_Status == true then
					fs2020_event("TOGGLE_FUEL_VALVE_ENG1")
				end
				if L_Ign_Switch1_Status == true then
					fs2020_event("TURBINE_IGNITION_SWITCH_SET1",0)
				end
			else
				fs2020_event("MIXTURE1_RICH")
				if L_Fuel_Valve1_Status ~= true then
					fs2020_event("TOGGLE_FUEL_VALVE_ENG1")
				end
				if L_Ign_Switch1_Status == false then
					fs2020_event("TURBINE_IGNITION_SWITCH_SET1",1)
				end	
			end
		end
		sound_play(click_snd)
    end
end
button_add(nil,nil, 151,30,100,100, callback_Engine1_Run_Toggle)

--ENGINE 2
function callback_Engine2_Run_Toggle()
    if right_run==0 then    --if button cover is down, play fail sound and don't start the engine
        sound_play(fail_snd)
    else    -- run toggle logic if cover is open
		if  (L_Battery_Master_Status == true or L_External_Power_Status == true or L_Bus_Volts > 5) then
			if L_Mix2_Status == true then
				fs2020_event("MIXTURE2_LEAN")
				if L_Fuel_Valve2_Status == true then
					fs2020_event("TOGGLE_FUEL_VALVE_ENG2")
				end
				if L_Ign_Switch2_Status == true then
					fs2020_event("TURBINE_IGNITION_SWITCH_SET2",0)
				end
			else
				fs2020_event("MIXTURE2_RICH")
				if L_Fuel_Valve2_Status ~= true then
					fs2020_event("TOGGLE_FUEL_VALVE_ENG2")
				end
				if L_Ign_Switch2_Status == false then
					fs2020_event("TURBINE_IGNITION_SWITCH_SET2",1)
				end	
			end
		end
		sound_play(click_snd)
	end
end
button_add(nil,nil, 421,30,100,100, callback_Engine2_Run_Toggle)

---------Starters--------------
function callback_Starter1_Toggle()
   fs2020_event("TOGGLE_STARTER1")
   sound_play(click_snd)
end
button_add(nil,nil, 190,250,80,50, callback_Starter1_Toggle)

function callback_Starter2_Toggle()
   fs2020_event("TOGGLE_STARTER2")
   sound_play(click_snd)
end
button_add(nil,nil, 395,250,80,50, callback_Starter2_Toggle)

function callback_Starter_Diseng_Toggle()
   sound_play(click_snd)
   if L_Starter1_Status == true then
       fs2020_event("TOGGLE_STARTER1")
   end
   if L_Starter2_Status == true then
       fs2020_event("TOGGLE_STARTER2")
   end
end
button_add(nil,nil, 295,250,80,50, callback_Starter_Diseng_Toggle)

                          
------Rudder Trim------------                                                                                    
function callback_Rudder_Trim_Left_Start()
   timer_id1 = timer_start(0, 100,Rudder_Trim_Left)
   rotate(Rudder_Trim_Knob, -90 )
   rotate(img_rudder_knob_indicator_backlight, -90 )
   sound_play(click_snd)
end
function callback_Rudder_Trim_Left_End()
       timer_stop(timer_id1)
       rotate(Rudder_Trim_Knob, 0 )
       rotate(img_rudder_knob_indicator_backlight, 0 )
       sound_play(click_snd)
end
function Rudder_Trim_Left()
   fs2020_event("RUDDER_TRIM_LEFT")
end   
button_add(nil,nil, 130,650,80,150, callback_Rudder_Trim_Left_Start, callback_Rudder_Trim_Left_End) 


                                            
function callback_Rudder_Trim_Right_Start()
    timer_id2 = timer_start(0, 100,Rudder_Trim_Right)
    rotate(Rudder_Trim_Knob, 90 )
    rotate(img_rudder_knob_indicator_backlight, 90 )   
    sound_play(click_snd)
end
function callback_Rudder_Trim_Right_End()
    timer_stop(timer_id2)
    rotate(Rudder_Trim_Knob, 0 )      
    rotate(img_rudder_knob_indicator_backlight, 0 )        
    sound_play(click_snd)       
end
function Rudder_Trim_Right()
    fs2020_event("RUDDER_TRIM_Right")
end   
button_add(nil,nil, 275,650,80,150, callback_Rudder_Trim_Right_Start, callback_Rudder_Trim_Right_End)                         

                          
-------Elevator Trim---------------                                                    
function callback_Elevator_Trim_Down_Start()
   timer_id3 = timer_start(0, 100,Elevator_Trim_Down)
   move(Elev_Trim_Knob, 425,380,95,127)
   sound_play(click_snd)
end
function callback_Elevator_Trim_Down_End()
       timer_stop(timer_id3)
       move(Elev_Trim_Knob, 425,395,95,127)
       sound_play(click_snd)
end
function Elevator_Trim_Down()
   fs2020_event("ELEV_TRIM_DN")

end   
button_add(nil,nil, 425,400,100,50, callback_Elevator_Trim_Down_Start, callback_Elevator_Trim_Down_End) 


                                            
function callback_Elevator_Trim_Up_Start()
   timer_id4 = timer_start(0, 100,Elevator_Trim_Up)
   move(Elev_Trim_Knob, 425,410,95,127)
   sound_play(click_snd)
end
function callback_Elevator_Trim_Up_End()
       timer_stop(timer_id4)
       move(Elev_Trim_Knob, 425,395,95,127)       
       sound_play(click_snd)       
end
function Elevator_Trim_Up()
   fs2020_event("ELEV_TRIM_UP")

end   
button_add(nil,nil, 425,460,100,50, callback_Elevator_Trim_Up_Start, callback_Elevator_Trim_Up_End)   
                                                                 
------Aileron Trim--------------------

function callback_Aileron_Trim_Left_Start()
   timer_Aileron_L = timer_start(0, 20,Aileron_Trim_Left)
   move(AILERON_Trim_Knob, 125,400,127,95)
   sound_play(click_snd)
end
function callback_Aileron_Trim_Left_End()
       timer_stop(timer_Aileron_L)
       move(AILERON_Trim_Knob, 135,400,127,95)
       sound_play(click_snd)
end
function Aileron_Trim_Left()
   fs2020_event("AILERON_TRIM_LEFT")
end   
button_add(nil,nil, 140,390,60,130, callback_Aileron_Trim_Left_Start, callback_Aileron_Trim_Left_End) 


                                            
function callback_Aileron_Trim_Right_Start()
   timer_Aileron_R = timer_start(0, 20,Aileron_Trim_Right)
   move(AILERON_Trim_Knob, 145,400,127,95)
   sound_play(click_snd)
end
function callback_Aileron_Trim_Right_End()
       timer_stop(timer_Aileron_R)
       move(AILERON_Trim_Knob, 135,400,127,95)    
       sound_play(click_snd)          
end
function Aileron_Trim_Right()
   fs2020_event("AILERON_TRIM_RIGHT")
end   
button_add(nil,nil, 200,390,60,130, callback_Aileron_Trim_Right_Start, callback_Aileron_Trim_Right_End)                         

--Add graphics for both states

img_L_Closed = img_add("cover_l_closed.png", 120 ,5,152,146)
img_L_Open = img_add("cover_l_open.png", 120 ,5,152,146)
visible(img_L_Closed, true)
visible(img_L_Open, false)

img_R_Closed = img_add("cover_r_closed.png", 400 ,5,152,146)
img_R_Open = img_add("cover_r_open.png", 400 ,5,152,146)
visible(img_R_Closed, true)
visible(img_R_Open, false)


function callback_cover_l_toggle()
    if left_run == 0 then
        left_run =1
        visible(img_L_Closed, false)
        visible(img_L_Open, true)
        sound_play(cover_open_snd)
     else
        left_run = 0
        visible(img_L_Closed, true)
        visible(img_L_Open, false)
        sound_play(cover_close_snd)
     end
end
button_add(nil, nil ,120 ,5,30,146, callback_cover_l_toggle)                                                                                                                                                          

function callback_cover_r_toggle()
    if right_run == 0 then
        right_run =1
        visible(img_R_Closed, false)
        visible(img_R_Open, true)
        sound_play(cover_open_snd)
    else
        right_run = 0
        visible(img_R_Closed, true)
        visible(img_R_Open, false)
        sound_play(cover_close_snd)
    end    
end
button_add(nil, nil, 525 ,5,30,146, callback_cover_r_toggle)                                                                                                                                                          
                                                                                                                                                                                                                                                                                                              
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
                                   