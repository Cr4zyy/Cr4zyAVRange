-- Dragon is a god
-- all 'zero number' ranges must be set to 0.2

local alienVisionEnabled = true
local alienRanges = { }
alienRanges["Parasite"] = 0.2
alienRanges["XenocideLeap"] = 0.2
alienRanges["SpitSpray"] = 5.3
alienRanges["BileBomb"] = 0.2
alienRanges["BabblerAbility"] = 0.2
alienRanges["Spores"] = 0.2
alienRanges["LerkUmbra"] = 17
alienRanges["SwipeBlink"] = 1.6
alienRanges["StabBlink"] = 1.9
alienRanges["Gore"] = 2.2 //This is a guess, its changed by viewangle...
alienRanges["BoneShield"] = 0.2
alienRanges["Metabolize"] = 0.2
alienRanges["DropStructureAbility"] = 0.2

function Alien:UpdateClientEffects(deltaTime, isLocal)

    Player.UpdateClientEffects(self, deltaTime, isLocal)
    
    // If we are dead, close the evolve menu.
    if isLocal and not self:GetIsAlive() and self:GetBuyMenuIsDisplaying() then
        self:CloseMenu()
    end
    
    self:UpdateEnzymeEffect(isLocal)
    self:UpdateElectrified(isLocal)
    self:UpdateMucousEffects(isLocal)
    
    if isLocal and self:GetIsAlive() then
    
        local darkVisionFadeAmount = 1
        local darkVisionFadeTime = 0.2
        local darkVisionPulseTime = 4
        local range = 0
        local darkVisionState = self:GetDarkVisionEnabled()

        if self.lastDarkVisionState ~= darkVisionState then

            if darkVisionState then
            
                self.darkVisionTime = Shared.GetTime()
                self:TriggerEffects("alien_vision_on") 
                
            else
            
                self.darkVisionEndTime = Shared.GetTime()
                self:TriggerEffects("alien_vision_off")
                
            end
            
            self.lastDarkVisionState = darkVisionState
        
        end
        
        if not darkVisionState then
            darkVisionFadeAmount = Clamp(1 - (Shared.GetTime() - self.darkVisionEndTime) / darkVisionFadeTime, 0, 1)
        end
        
        local player = Client.GetLocalPlayer()

        if player ~= nil then

            local ability = player:GetActiveWeapon()
			if ability and ability:isa("Ability") then
				if alienRanges[ability:GetClassName()] then
					range = alienRanges[ability:GetClassName()]
				else
					range = ability:GetRange()
				end
			else
				range = 0
			end
            
        end
        
        local useShader = Player.screenEffects.darkVision 
        
        if useShader then
        
            useShader:SetActive(alienVisionEnabled)            
            useShader:SetParameter("startTime", self.darkVisionTime)
            useShader:SetParameter("time", Shared.GetTime())
            useShader:SetParameter("amount", darkVisionFadeAmount)
            -- Print(ToString(range))
            useShader:SetParameter("abilityRange", range)
            
        end
        
        self:UpdateRegenerationEffect()
        
    end
    
end

-- lets you control how bright the bite aid is
local function SetBiteOpacity(opacityValue)

	local useShader = Player.screenEffects.darkVision
	local opacity = tonumber(opacityValue)
	
    if useShader then
		-- so if there is no mod default values are 0 in shader and we have to correct for that incase people dont run this mod
		if IsNumber(opacity) and opacity >= 0 and opacity <= 1 then
			opacity = math.abs(opacity - 1)
			useShader:SetParameter("opacityValue", opacity)
			Shared.Message("Bite Aid opacity value set at: " .. opacityValue)
		else
				Shared.Message("Usage: biteaid 0.0-1.0")
				Shared.Message("You tried: " .. opacityValue)
				Shared.Message("Setting to default: 1")
				useShader:SetParameter("opacityValue", 0)
		end
    end
    
end

 Event.Hook("Console_biteaid", SetBiteOpacity)