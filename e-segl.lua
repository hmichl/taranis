-- e-segl.lua
--
-- LUA-telemetry script for FrSKY Taranis X9D[+]
--
-- This telemetry script shows basic information which is 
-- useful for electric gliders
--
-- top left is clock / flightmode
-- bottom left altitude in biggest possible font
-- right of the current altitude it shows
--   - maximum height
--   - minimum height
--   - accumulated height without motor
--   - accumulated height with motor
-- the right side of the display shows max / current and lowest voltage
-- bottom right shows used capacity of battery
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

-- draw tx-voltage / clock / flightmode
  lcd.drawText( 1, 2, string.format("%2.1fV", getValue("tx-voltage")), MIDSIZE)
  lcd.drawText( 33, 2, string.format("%02d:%02d", datenow.hour, datenow.min), MIDSIZE)
  if fmt == "" then
    lcd.drawText( 70, 2, string.format("Flugphase %2d", fmn), MIDSIZE)
  else
    lcd.drawText( 70, 2, fmt, MIDSIZE)
  end
-- Altitude
  lcd.drawNumber(85, 22, Alt, XXLSIZE+RIGHT)
  lcd.drawText(lcd.getLastPos(), 48, " m", MIDSIZE)
  lcd.drawText(105, 17, "Max", SMLSIZE)
  lcd.drawText(160, 17, string.format("%d m", AltP), SMLSIZE+RIGHT)
  lcd.drawText(105, 27, "Min", SMLSIZE)
  lcd.drawText(160, 27, string.format("%d m", AltM), SMLSIZE+RIGHT)
  lcd.drawText(105, 37, "Ther", SMLSIZE)
  lcd.drawText(160, 37, string.format("%d m", TAlt), SMLSIZE+RIGHT)
  lcd.drawText(105, 47, "MoFl", SMLSIZE)
  lcd.drawText(160, 47, string.format("%d m", MAFl), SMLSIZE+RIGHT)
  lcd.drawText(105, 57, "Moto", SMLSIZE)
  lcd.drawText(160, 57, string.format("%d m", MAlt), SMLSIZE+RIGHT)
-- Voltages
  lcd.drawText( 210, 2, string.format("%3.1fV+", getValue("VFAS+")), MIDSIZE+RIGHT)
  lcd.drawText( 204, 17, string.format("%3.1fV", getValue("VFAS")), MIDSIZE+RIGHT)
  if Battlow == 1 then   -- battery voltage is or was low
    lcd.drawText( 210, 32, string.format("%3.1fV-", getValue("VFAS-")), MIDSIZE+RIGHT+BLINK+INVERS)
  else
    lcd.drawText( 210, 32, string.format("%3.1fV-", getValue("VFAS-")), MIDSIZE+RIGHT)
  end
-- Used Capacity
  lcd.drawNumber(194, 47, getValue("Cnsp"), MIDSIZE+RIGHT)
  lcd.drawText( lcd.getLastPos(), 52, "mAh", SMLSIZE)
-- check Telemetry
  if getValue( 'RSSI') <= 1 then
    lcd.drawText( 20, 20, "  Telemetrie verloren !!!  ", MIDSIZE+BLINK+INVERS)
  end
end

return { run=run, background=bg, init=init }
