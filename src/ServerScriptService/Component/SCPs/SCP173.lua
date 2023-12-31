local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Component = require(ReplicatedStorage.Packages.Component)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Waiter = require(ReplicatedStorage.Packages.Waiter)

local SightProbe = require(ServerScriptService.Component.Probes.SightProbeServer)

local component = Component.new {
    Tag = "SCP173",
    Ancestors = { workspace }
}

function component:Construct()
    self.observed = false
    self.controllerManager = self.Instance.ControllerManager :: ControllerManager
    self.groundController = self.Instance.ControllerManager.GroundController :: GroundController
    self.sightProbes = Waiter.get.descendants(self.Instance, {tag = "SightProbe"})
end

function component:SteppedUpdate()
    self:tryUpdateState()
end

function component:isObserved()
    return TableUtil.Some(self.sightProbes, function(sightProbe)
        return SightProbe:FromInstance(sightProbe).isObserved
    end)
end

function component:tryUpdateState()
    if self.observed then
        if not self:isObserved() then
            self:updateState(false)
        end
    else
        if self:isObserved() then
            self:updateState(true)
        end
    end
end

function component:updateState(observed)
    self.observed = observed
    if observed then
        self.groundController.TurnSpeedFactor = 0
        self.groundController.MoveSpeedFactor = 0
        self.Instance.PrimaryPart:SetAttribute("DamagePerTouch", 0)
    else
        self.groundController.TurnSpeedFactor = 1
        self.groundController.MoveSpeedFactor = 1
        self.Instance.PrimaryPart:SetAttribute("DamagePerTouch", -1)
    end
end



return component