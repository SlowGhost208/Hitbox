local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage.Modules

local FastSignal = require(Modules.FastSignal)
local Trove = require(Modules.Trove)

local Hitbox = {}
Hitbox.__index = Hitbox
Hitbox.DotProduct = false
Hitbox.AllowMultiHit = true
Hitbox.IgnoreIFrames = false
Hitbox.Size = Vector3.new(5, 5, 5)
Hitbox.Offset = CFrame.new(0, 0, -3)
Hitbox.HitboxTime = 0.2

local Params = OverlapParams.new()
Params.FilterType = Enum.RaycastFilterType.Include
Params.FilterDescendantsInstances = {workspace.Players}

function Hitbox.new(Character : Model, Object : (BasePart | Attachment))
	local Char = Character

	local Humanoid : Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
	local RootPart = Humanoid.RootPart

	local self = {} 

	self.Trove = Trove.new()
	self.Trove:AttachToInstance(Object ~= nil and Object or Character)

	self.OnHit = self.Trove:Construct(FastSignal.new)

	self.Detected = {}

	self.StartTime = os.clock() -- might use tick() but if it works it works

	local Exists = Object ~= nil and Object:IsDescendantOf(game) or Character:IsDescendantOf(game)

	self.Connection = self.Trove:Connect(RunService.Heartbeat, function()
		if os.clock() - self.StartTime > self.HitboxTime or not Exists then
			self.Trove:Destroy()

			table.clear(self)
			setmetatable(self, nil)

			return
		end

		local HitboxCFrame = nil

		if Object == nil then
			local StartCFrame = RootPart.CFrame

			if self.DotProduct then
				local RootCFrame = Humanoid.RootPart.CFrame;
				local MoveDirection = Humanoid.MoveDirection;

				local DotThing = Vector3.new(
					math.abs(MoveDirection:Dot(RootCFrame.LookVector)), 0,
					math.abs(MoveDirection:Dot(RootCFrame.RightVector)) / 2
				);

				HitboxCFrame = CFrame.new(MoveDirection * DotThing:Dot(self.Size) / 2) * StartCFrame
			else
				HitboxCFrame = StartCFrame
			end
		else
			HitboxCFrame = Object:IsA("Attachment") and Object.WorldCFrame or Object.CFrame
		end

		local FinalHitboxCFrame = HitboxCFrame * self.Offset
		local Bounds = workspace:GetPartBoundsInBox(FinalHitboxCFrame, self.Size, Params)

		for _, Hit in ipairs(Bounds) do
			local EnemyChar : Model? = Hit.Parent
			local EnemyCharHumanoid = EnemyChar:FindFirstChildOfClass("Humanoid")

			if EnemyChar and not EnemyChar:GetAttribute("IFrames") and EnemyCharHumanoid and EnemyCharHumanoid.Health > 0 and not self.Detected[EnemyChar] and EnemyChar ~= Character then
				if EnemyChar:GetAttribute("IFrames") then
					if self.IgnoreIFrames then
						self.OnHit:Fire(EnemyChar, EnemyCharHumanoid, EnemyCharHumanoid.RootPart)
						self.Detected[EnemyChar] = true

						if not self.AllowMultiHit then
							self.Trove:Destroy()
							break
						end
					end
				else

					self.OnHit:Fire(EnemyChar, EnemyCharHumanoid, EnemyCharHumanoid.RootPart)
					self.Detected[EnemyChar] = true

					if not self.AllowMultiHit then
						self.Trove:Destroy()
						break
					end
				end
			end
		end
	end)

	return setmetatable(self, Hitbox)
end

return Hitbox
