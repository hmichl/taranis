-- xl-seg.lua
--
-- LUA-telemetry script for FrSKY Taranis X-Lite Pro
--
-- This telemetry script shows basic information which is 
-- useful for electric gliders
--
-- top left is clock / flightmode / flighttime
-- as the display is rather small there exist two subscreens
-- they can be viewed by long-pressing the joystick up (1) or right (2)
-- subscreen 1 views
--   - bottom left altitude in biggest possible font
--   - the right side of the display shows max / current and lowest voltage
--   - bottom right shows used capacity of battery
-- subscreen 2 views
--   - maximum height
--   - minimum height
--   - accumulated height without motor
--   - accumulated height with motor during one flight
--   - accumulated height with motor with one battery
--
-- have fun :-)
-- 
-- Necessary logical switches
-- ls45 true if motor running
-- ls46 true to reset flight
-- ls47 true to reset battery
-- ls50 true if battery voltage to low
--
-- Necessary telemetry values
-- Alt  - current altitude
-- VFAS - current voltage
-- Cnsp - used capacity
-- RSSI - RSSI :-)
--
-- Script delivers the following telemetry values 
--   (detect by searching for sensors while script is running)
-- TAlt - sum of altitude gained without motor
-- MAlt - sum of altitude gained with motor
-- MAFl - sum of altitude gained with motor per flight
--


 
local function init()
  OAlt = 0
  TAlt = 0
  MAlt = 0
  MAFl = 0
  Battlow = 0
  Subscreen = 1
end

local function bg()
-- process values also if telemetry screen not visible
--
  Alt = getValue("Alt")
  AltM = getValue("Alt-")
  AltP = getValue("Alt+")
  if Alt >= OAlt then   -- did the height increase?
    if getValue("ls45") >= 100 then  -- motor running
      MAlt = MAlt + (Alt - OAlt)
      MAFl = MAFl + (Alt - OAlt)
    else                             -- we are in "quiet mode" :-)
      TAlt = TAlt + (Alt - OAlt)
    end
  end
  OAlt = Alt   -- set old altitude to current
  -- ID 15, Sensor 0x20  - accumulated height without motor
  setTelemetryValue( 32, 0, 15, TAlt, 9, 0, "TAlt")  
  -- ID 15, Sensor 0x21  - accumulated height with motor summary
  setTelemetryValue( 33, 0, 15, MAlt, 9, 0, "MAlt")  
  -- ID 15, Sensor 0x22  - accumulated height with motor per flight
  setTelemetryValue( 34, 0, 15, MAFl, 9, 0, "MAFl")  
  if getValue("ls46") >= 100 then  -- reset flight
    TAlt = 0
    MAFl = 0
  end
  if getValue("ls47") >= 100 then  -- reset battery
    MAlt = 0
    MAFl = 0
    TAlt = 0
    Battlow = 0
  end
  if getValue("ls50") >= 100 then   -- battery voltage low
    Battlow = 1
  end
end


local function run(event)
----------------------------------
  local datenow = getDateTime()
----------------------------------
  lcd.clear()

  fmn,fmt = getFlightMode()
  flighttime = model.getTimer( 0)
  if event == 68 then
    Subscreen = 1
  end
  if event == 69 then
    Subscreen = 2
  end 

-- draw tx-voltage / clock / flightmode / Timer1
  lcd.drawText( 1, 2, string.format("%2.1fV", getValue("tx-voltage")), 0)
  lcd.drawText( 25, 2, string.format("%02d:%02d", datenow.hour, datenow.min), 0)
  if fmt == "" then
    lcd.drawText( 50, 2, string.format("Flugphase %2d", fmn), 0)
  else
    lcd.drawText( 50, 2, fmt, 0)
  end
  lcd.drawTimer( 90, 2, flighttime.value, TIMEHOUR)

  if Subscreen == 1 then
    -- Subscreen 1 - normal flight display
    -- Press "UP"
    -- Altitude
    lcd.drawNumber(75, 15, Alt, XXLSIZE+RIGHT)
    lcd.drawText(lcd.getLastPos(), 47, "m", SMLSIZE)
    -- Voltages
    lcd.drawText( 120, 12, string.format("%3.1fV", getValue("VFAS+")), MIDSIZE+RIGHT)
    lcd.drawText(lcd.getLastPos(), 12, "+", MIDSIZE)
    lcd.drawText( 120, 25, string.format("%3.1fV", getValue("VFAS")), MIDSIZE+RIGHT)
    if Battlow == 1 then   -- battery voltage is or was low
      lcd.drawText( 120, 38, string.format("%3.1fV", getValue("VFAS-")), MIDSIZE+RIGHT+BLINK+INVERS)
      lcd.drawText(lcd.getLastPos(), 38, "-", MIDSIZE+BLINK+INVERS)

    else
      lcd.drawText( 120, 38, string.format("%3.1fV", getValue("VFAS-")), MIDSIZE+RIGHT)
      lcd.drawText(lcd.getLastPos(), 38, "-", MIDSIZE)
    end
    -- Capacity
    lcd.drawNumber(112, 51, getValue("Cnsp"), MIDSIZE+RIGHT)
    lcd.drawText(lcd.getLastPos(), 55, "mAh", SMLSIZE)

  end
  if Subscreen == 2 then
    -- Subscreen 2 - statistical data for after-flight analysis  
    -- Press "RIGHT"
    -- Height information
    lcd.drawText( 5, 17, "Max Hoehe", SMLSIZE)
    lcd.drawText( 100, 17, string.format("%d m", AltP), SMLSIZE+RIGHT)
    lcd.drawText( 5, 27, "Min Hoehe", SMLSIZE)
    lcd.drawText( 100, 27, string.format("%d m", AltM), SMLSIZE+RIGHT)
    lcd.drawText( 5, 37, "Up Thermik", SMLSIZE)
    lcd.drawText( 100, 37, string.format("%d m", TAlt), SMLSIZE+RIGHT)
    lcd.drawText( 5, 47, "Up Motor Flug", SMLSIZE)
    lcd.drawText( 100, 47, string.format("%d m", MAFl), SMLSIZE+RIGHT)
    lcd.drawText( 5, 57, "Up Motor Akku", SMLSIZE)
    lcd.drawText( 100, 57, string.format("%d m", MAlt), SMLSIZE+RIGHT)
  end


  -- check Telemetry
  if getValue( 'RSSI') <= 1 then
    lcd.drawText( 5, 15, "  Telemetrie verloren !!!  ", MIDSIZE+BLINK+INVERS)
  end
end

return { run=run, background=bg, init=init }
