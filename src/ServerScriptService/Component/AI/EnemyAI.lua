local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Promise = require(ReplicatedStorage.Packages.Promise)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local component = Component.new {
    Tag = "EnemyAI",
    Ancestors = { workspace }
}

function component:Construct()
    self.controllerManager = self.Instance.ControllerManager :: ControllerManager
    self.target = nil
    self.path = PathfindingService:CreatePath({
        AgentRadius = 1.5,
        AgentHeight = 6,
        AgentCanJump = false,
        AgentCanClimb = false,
        WaypointSpacing = 4,
    })
end

function component:SteppedUpdate()
    local validTargets = self:getValidTargets()
    self.target = self:selectClosest(validTargets)
    if self.target then
        self:moveTo(self.target)
    end
end

function component:getPosition()
    return self.Instance.PrimaryPart.Position
end

function component:computePath(from: Vector3, to: Vector3)
    return Promise.new(function(resolve, reject)
        self.path:ComputeAsync(from, to)
        if self.path.Status == Enum.PathStatus.Success then
            resolve(self.path:GetWaypoints())
        else
            reject(self.path.Status)
        end
    end)
end

function component:getValidTargets()
    local targets = {}
    for _, player in game.Players:GetPlayers() do
        if player.Character and player.Character.PrimaryPart then
            table.insert(targets, player.Character.PrimaryPart)
        end
    end
    targets = TableUtil.Filter(targets, function(target)
        return self:computePath(self:getPosition(), target.Position)
        :andThen(function()
            return true
        end)
        :catch(function()
            return false
        end)
    end)
    return targets
end

function component:selectClosest(targets: {BasePart})
    local closest = TableUtil.Reduce(targets, function(a, b)
        local previousDistance = (a.Position - self:getPosition()).Magnitude
        local distance = (b.Position - self:getPosition()).Magnitude
        return if previousDistance < distance then a else b
    end)
    return closest
end

function component:moveTo(target: BasePart)
    self:computePath(self:getPosition(), target.Position)
    :andThen(function(waypoints)
        local waypoint = waypoints[2]
        if waypoint then
            local direction = (waypoint.Position - self:getPosition()).Unit
            self.controllerManager.MovingDirection = direction
        else
            self.controllerManager.MovingDirection = Vector3.new()
        end
    end)
    :catch(function()
        self.controllerManager.MovingDirection = Vector3.new()
    end)
end

return component