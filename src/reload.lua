---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

-- this file will be reloaded if it changes during gameplay,
-- 	so only assign to values or define things here.

if config.DoorIndicators.Enabled then

	function PopulateDoorRewardPreviewSubIcons_override(exitDoor, args)
		local subIcons = {}
		local room = exitDoor.Room

		if not args.RewardHidden and not args.SkipRoomSubIcons then

			if room.RewardPreviewIcon ~= nil then
				table.insert( subIcons, { Name = room.RewardPreviewIcon } )
			end

			local chosenRewardTypes = {}
			if args.CageRewards ~= nil then
				for i, cageReward in ipairs( args.CageRewards ) do
					table.insert( chosenRewardTypes, cageReward.RewardType )
				end
			else
				table.insert( chosenRewardTypes, args.ChosenRewardType )
			end

			local resourcesInRoom = {}

			for i, rewardType in ipairs( chosenRewardTypes ) do
				local consumableData = ConsumableData[rewardType]
				if consumableData ~= nil and consumableData.AddResources ~= nil then
					for resourceName in pairs( consumableData.AddResources ) do
						resourcesInRoom[resourceName] = true
					end
				end
			end

			if not exitDoor.SkipResourcePinIcons then
				local requirementArgs = { RoomSetName = room.RoomSetName }
				-- MOD START
				if CurrentRun.PylonRooms and CurrentRun.PylonRooms[room.Name] then
					table.insert(subIcons, { Name = "GUI\\Icons\\GhostPack" })
				end
				if Contains(room.LegalEncounters, "HealthRestore") then
					table.insert(subIcons, { Name = "ExtraLifeHeart" })
				end
				-- MOD END
				if room.HarvestPointsAllowed > 0 then
					table.insert(subIcons, { Name = "GatherIcon" }) -- MOD
					for i, option in ipairs( HarvestData.WeightedOptions ) do
						if option.AddResources ~= nil and IsGameStateEligible( option, option.GameStateRequirements, requirementArgs ) then
							for resourceName in pairs( option.AddResources ) do
								resourcesInRoom[resourceName] = true
							end
							break
						end
					end
				end
				if room.ShovelPointSuccess and HasAccessToTool( "ToolShovel" ) then
					table.insert(subIcons, { Name = "ShovelIcon" }) -- MOD
					for i, option in ipairs( ShovelPointData.WeightedOptions ) do
						if IsGameStateEligible( option, option.GameStateRequirements, requirementArgs ) then
							for resourceName in pairs( option.AddResources ) do
								-- Determine what plant this seed grows into
								local seedData = GardenData.Seeds[resourceName]
								if seedData ~= nil and #seedData.RandomOutcomes == 1 then
									for plantName in pairs( seedData.RandomOutcomes[1].AddResources ) do
										resourcesInRoom[plantName] = true
									end
								end
							end
							break
						end
					end
				end
				if room.PickaxePointSuccess and HasAccessToTool( "ToolPickaxe" ) then
					table.insert(subIcons, { Name = "PickaxeIcon" }) -- MOD
					for i, option in ipairs( PickaxePointData.WeightedOptions ) do
						if IsGameStateEligible( option, option.GameStateRequirements, requirementArgs ) then
							resourcesInRoom[option.ResourceName] = true
							break
						end
					end
				end
				if room.ExorcismPointSuccess and HasAccessToTool( "ToolExorcismBook", requirementArgs ) then
					table.insert(subIcons, { Name = "ExorcismIcon" }) -- MOD
					resourcesInRoom.MemPointsCommon = true
				end
				-- MOD START
				if room.FishingPointSuccess and HasAccessToTool("ToolFishingRod") then
					table.insert(subIcons, { Name = "FishingIcon" })
				end
				-- MOD END
				-- no need to check for fish; their appearance is random and they aren't used in recipes
			end

			local hasPin = false
			local hasEnoughForPins = true
			for resourceName in pairs( resourcesInRoom ) do
				local amountNeededByPins = GetResourceAmountNeededByPins( resourceName )
				if amountNeededByPins > 0 then
					hasPin = true
					if not HasResource( resourceName, amountNeededByPins ) then
						hasEnoughForPins = false
						break
					end
				end
			end

			if hasPin then
				local forgetMeNotIconData = { Name = "RoomRewardSubIcon_ForgetMeNot" }
				if hasEnoughForPins then
					forgetMeNotIconData.Animation = "RoomRewardSubIcon_ForgetMeNot_Complete"
				end
				table.insert( subIcons, forgetMeNotIconData )
			end

			local existingPinIconId = exitDoor.AdditionalIcons.RoomRewardSubIcon_ForgetMeNot
			if existingPinIconId ~= nil then
				if hasPin then
					SetAlpha({ Id = existingPinIconId, Fraction = 1.0, Duration = 0.2 })
				else
					SetAlpha({ Id = existingPinIconId, Fraction = 0.0, Duration = 0.2 })
				end
			end

			local hasOnion = false
			for i, rewardType in ipairs( chosenRewardTypes ) do
				if rewardType == "Boon" or rewardType == "HermesUpgrade" then
					if GetNumShrineUpgrades( "BoonSkipShrineUpgrade" ) > CurrentRun.BiomeBoonSkipCount then
						hasOnion = true
						table.insert( subIcons, { Name = "RoomRewardSubIcon_Onion" } )
						break
					end
				end
			end

			local existingOnionIconId = exitDoor.AdditionalIcons.RoomRewardSubIcon_Onion
			if existingOnionIconId ~= nil then
				if hasOnion then
					SetAlpha({ Id = existingOnionIconId, Fraction = 1.0, Duration = 0.2 })
				else
					SetAlpha({ Id = existingOnionIconId, Fraction = 0.0, Duration = 0.2 })
				end
			end

			local hasQuestIcon = false
			local encountersChecked = {}
			if room.LegalEncounters ~= nil then
				for k, encounterName in pairs( room.LegalEncounters ) do
					if not encountersChecked[encounterName] and not GameState.EncountersCompletedCache[encounterName] and HasActiveQuestForName( encounterName ) then
						local encounterData = EncounterData[encounterName]
						if encounterData.GameStateRequirements == nil or IsGameStateEligible( encounterData, encounterData.GameStateRequirements ) then
							hasQuestIcon = true
							break
						end
					end
					encountersChecked[encounterName] = true
				end
			end
			if not hasQuestIcon and room.ForceLootName ~= nil then
				local questTraitName = room.ForceLootName
				if SpellData[questTraitName] ~= nil then
					questTraitName = SpellData[questTraitName].TraitName or questTraitName
				end
				if not GameState.TraitsTaken[questTraitName] and HasActiveQuestForName( questTraitName ) then
					hasQuestIcon = true
				end
			end
			if hasQuestIcon then
				table.insert( subIcons, { Name = "RoomRewardSubIcon_FatedList" } )
			end
		end

		return subIcons
	end

	function mod.IsResourceIcon(icon)
		local iconsList = { "GatherIcon", "ShovelIcon", "ExorcismIcon", "PickaxeIcon", "FishingIcon", "GUI\\Icons\\GhostPack", "ExtraLifeHeart" }
		if Contains(iconsList, icon) then
			return true
		end
		return false
	end

	function AddDoorInfoIcon_override(args)
		args = args or {}
		local exitDoor = args.Door
		local iconId = nil

		--MOD START
		if args.Name == nil then
			return
		end
		--MOD END

		if args.ReUseIds and exitDoor.AdditionalIcons[args.Name] ~= nil then
			iconId = exitDoor.AdditionalIcons[args.Name]
		else
			iconId = SpawnObstacle({ Name = "BlankGeoObstacle", Group = args.Group, SortById = true })
			local offsetAngle = 330
			if IsHorizontallyFlipped({ Id = exitDoor.ObjectId }) then
				offsetAngle = 30
				FlipHorizontal({ Id = iconId })
			end
			local offset = CalcOffset( math.rad( offsetAngle ), args.IsoOffset )
			--MOD START
			if mod.IsResourceIcon(args.Animation) then
				offset.Y = offset.Y - 40
				local backingId = SpawnObstacle({ Name = "circle01", Group = "Combat_UI_World_Backing", SortById = true })
				SetColor({ Id = backingId, Color = Color.Black, Duration = 0 })
				SetScale({ Id = backingId, Fraction = 0.25 })
				Attach({ Id = backingId, DestinationId = args.DoorIconId, OffsetZ = 100, OffsetX = offset.X, OffsetY = offset.Y })
				table.insert(exitDoor.AdditionalIcons, backingId)
			end
			if args.Animation == "GUI\\Icons\\GhostPack" then
				animId = SpawnObstacle({ Name = "BlankGeoObstacle", Group = args.Group, SortById = true })
				Attach({ Id = animId, DestinationId = args.DoorIconId, OffsetY = 100 })
				SetAnimation({ DestinationId = animId, Name = "SoulPylonGhostEnergyHub" })
				SetScale({ Id = animId, Fraction = 0.33 })
			end
			--MOD END
			Attach({ Id = iconId, DestinationId = args.DoorIconId, OffsetZ = 100, OffsetX = offset.X, OffsetY = offset.Y })
		end
		SetAnimation({ DestinationId = iconId, Name = args.Animation })
		exitDoor.AdditionalIcons[args.Name] = iconId
	end
end

if config.PermanentLocationCount.Enabled then
	function ShowDepthCounter()
		local screen = { Name = "RoomCount", Components = {} }
		screen.ComponentData = {
			RoomCount = DeepCopyTable(ScreenData.TraitTrayScreen.ComponentData.RoomCount)
		}
		CreateScreenFromData(screen, screen.ComponentData)
	end
end

if config.RepeatableChaosTrials.Enabled then
	function BountyBoardScreenDisplayCategory_override(screen, categoryIndex)
		local components = screen.Components
		local category = screen.ItemCategories[categoryIndex]
		local slotName = category.Name

		screen.ActiveCategoryIndex = categoryIndex

		screen.ItemStartX = screen.ItemStartX + ScreenCenterNativeOffsetX
		screen.ItemStartY = screen.ItemStartY + ScreenCenterNativeOffsetY

		local itemLocationX = screen.ItemStartX
		local itemLocationY = screen.ItemStartY

		local activeBounties = {}
		local completedBounties = {}
		--MOD START
		local ineligibleBounties = {}
		--MOD END

		for i, bountyName in ipairs( screen.ItemCategories[screen.ActiveCategoryIndex] ) do
			local bountyData = BountyData[bountyName]
			if not bountyData.DebugOnly then
				if GameState.PackagedBountyClears[bountyName] ~= nil then
					table.insert(completedBounties, bountyData)
				elseif IsGameStateEligible(bountyData, bountyData.UnlockGameStateRequirements) then
					table.insert(activeBounties, bountyData)
					--MOD START
				else
					table.insert(ineligibleBounties, bountyData)
					--MOD END
				end
			end
		end

		local firstUseable = false
		screen.NumItems = 0

		for k, bountyData in ipairs( activeBounties ) do

			-- BountyButton
			screen.NumItems = screen.NumItems + 1
			local button = CreateScreenComponent({ Name = "BlankInteractableObstacle", X = itemLocationX, Y = itemLocationY, Group = screen.ComponentData.DefaultGroup })
			button.MouseOverSound = "/SFX/Menu Sounds/MirrorMenuToggle"
			button.OnPressedFunctionName = "StartPackagedBounty"
			button.OnMouseOverFunctionName = "MouseOverBounty"
			button.OnMouseOffFunctionName = "MouseOffBounty"
			button.Data = bountyData
			button.Index = screen.NumItems
			button.Screen = screen
			AttachLua({ Id = button.Id, Table = button })
			local bountyButtonKey = screen.ButtonName..screen.NumItems
			components[bountyButtonKey] = button

			local activeFormat = screen.ActiveFormat
			activeFormat.Id = button.Id
			activeFormat.Text = bountyData.Text or bountyData.Name
			activeFormat.LuaKey = "TempTextData"
			activeFormat.LuaValue = bountyData
			CreateTextBox( activeFormat )

			newButtonKey = "NewIcon"..screen.NumItems
			if not GameState.QuestsViewed[bountyData.Name] then
				-- New icon
				components[newButtonKey] = CreateScreenComponent({ Name = "BlankObstacle", Group = "Combat_Menu" })
				SetAnimation({ DestinationId = components[newButtonKey].Id , Name = "QuestLogNewQuest" })
				Attach({ Id = components[newButtonKey].Id, DestinationId = components[bountyButtonKey].Id, OffsetX = screen.NewIconOffsetX, OffsetY = screen.NewIconOffsetY })
			end

			if IsGameStateEligible( bountyData, bountyData.CompleteGameStateRequirements ) then
				local activeFlash = screen.ActiveFlash
				activeFlash.Id = button.Id
				Flash( activeFlash )
			end

			itemLocationY = itemLocationY + screen.ItemSpacingY
		end
		--MOD START
		for k, bountyData in ipairs(ineligibleBounties) do
			-- BountyButton
			screen.NumItems = screen.NumItems + 1
			local button = CreateScreenComponent({ Name = "BlankInteractableObstacle", X = itemLocationX, Y = itemLocationY, Group = screen.ComponentData.DefaultGroup })
			button.MouseOverSound = "/SFX/Menu Sounds/DialoguePanelOutMenu"
			button.OnMouseOverFunctionName = "MouseOverBounty"
			button.OnMouseOffFunctionName = "MouseOffBounty"
			button.OnPressedFunctionName = "BountyBoardIneligiblePresentation"
			button.Data = bountyData
			button.Index = screen.NumItems
			button.Screen = screen
			AttachLua({ Id = button.Id, Table = button })
			local bountyButtonKey = screen.ButtonName .. screen.NumItems
			components[bountyButtonKey] = button

			local ineligibleFormat =
			{
				Color = Color.CostUnaffordableDark,
				FontSize = 22,
				OffsetX = -10, OffsetY = 0,
				Font = "P22UndergroundSCMedium",
				OutlineThickness = 0,
				OutlineColor = {0,0,0,0.5},
				ShadowBlur = 0, ShadowColor = {0,0,0,0.7}, ShadowOffset={0, 2},
				Justification = "Center",
				DataProperties =
				{
					OpacityWithOwner = true,
				},
			}
			ineligibleFormat.Id = button.Id
			ineligibleFormat.Text = bountyData.Text or bountyData.Name
			ineligibleFormat.LuaKey = "TempTextData"
			ineligibleFormat.LuaValue = bountyData
			CreateTextBox(ineligibleFormat)

			itemLocationY = itemLocationY + screen.ItemSpacingY
		end

		for k, bountyData in ipairs(completedBounties) do
			-- BountyButton
			screen.NumItems = screen.NumItems + 1
			local button = CreateScreenComponent({ Name = "BlankInteractableObstacle", X = itemLocationX, Y = itemLocationY, Group = screen.ComponentData.DefaultGroup })
			button.MouseOverSound = "/SFX/Menu Sounds/DialoguePanelOutMenu"
			button.Data = bountyData
			if bountyData.Repeatable then
				button.OnPressedFunctionName = "StartPackagedBounty"
			else
				button.OnPressedFunctionName = "StartPackagedBounty"
				if not config.RepeatableChaosTrials.RepeatableReward then
					button.Data["ForcedReward"] = nil
					button.Data.LootOptions = {
						{
							Name = "MetaCurrencyRange",
							Overrides =
							{
								CanDuplicate = false,
								AddResources =
								{
									MetaCurrency = 50,
								},
							},
						},
					}
				end
			end
			button.OnMouseOverFunctionName = "MouseOverBounty"
			button.OnMouseOffFunctionName = "MouseOffBounty"
			button.Index = screen.NumItems
			button.Screen = screen
			AttachLua({ Id = button.Id, Table = button })
			local bountyButtonKey = screen.ButtonName .. screen.NumItems
			components[bountyButtonKey] = button

			local completedFormat = screen.CompletedFormat
			completedFormat.Id = button.Id
			completedFormat.Text = bountyData.Text or bountyData.Name
			completedFormat.LuaKey = "TempTextData"
			completedFormat.LuaValue = bountyData
			CreateTextBox(completedFormat)

			itemLocationY = itemLocationY + screen.ItemSpacingY
		end
	end
end
