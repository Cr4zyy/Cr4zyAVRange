local alienVisionEnabled = true

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
            
            if ability ~= nil and ability:isa("Ability") and ability:GetRange() ~= nil then
                range = ability:GetRange()
                if range == 100 then
                    range = 0
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
            Print(ToString(range))
            useShader:SetParameter("range", range)
            
        end
        
        self:UpdateRegenerationEffect()
        
    end
    
end