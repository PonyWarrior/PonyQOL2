---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

-- this file will be reloaded if it changes during gameplay,
-- 	so only assign to values or define things here.

if config.DoorIndicators.Enabled then

	function EphyraZoomOut_override(usee)
		AddInputBlock({ Name = "EphyraZoomOut" })
		thread(HideCombatUI, "EphyraZoomOut", { SkipHideObjectives = true })
		SetInvulnerable({ Id = CurrentRun.Hero.ObjectId })

		UseableOff({ Id = usee.ObjectId })

		ClearCameraClamp({ LerpTime = 0.8 })
		thread(SendCritters,
			{ MinCount = 20, MaxCount = 20, StartX = 0, RandomStartOffsetX = 1200, StartY = 300, MinAngle = 75, MaxAngle = 115, MinSpeed = 400, MaxSpeed = 2000, MinInterval = 0.001, MaxInterval = 0.001, GroupName =
			"CrazyDeathBats" })
		PanCamera({ Id = CurrentRun.Hero.ObjectId, OffsetY = -350, Duration = 1.0, EaseIn = 0, EaseOut = 0, Retarget = true })
		FocusCamera({ Fraction = CurrentRun.CurrentRoom.ZoomFraction * 0.95, Duration = 1, ZoomType = "Ease" })

		wait(0.50)

		local groupName = "Combat_Menu_Backing"
		local idsCreated = {}

		ScreenAnchors.EphyraZoomBackground = CreateScreenObstacle({ Name = "rectangle01", Group = "Combat_Menu", X = ScreenCenterX, Y = ScreenCenterY })
		table.insert(idsCreated, ScreenAnchors.EphyraZoomBackground)
		SetScale({ Ids = { ScreenAnchors.EphyraZoomBackground }, Fraction = 5 })
		SetColor({ Ids = { ScreenAnchors.EphyraZoomBackground }, Color = Color.Black })
		SetAlpha({ Ids = { ScreenAnchors.EphyraZoomBackground }, Fraction = 0, Duration = 0 })
		SetAlpha({ Ids = { ScreenAnchors.EphyraZoomBackground }, Fraction = 1.0, Duration = 0.2 })

		local letterboxIds = {}
		if ScreenState.NeedsLetterbox then
			local letterboxId = CreateScreenObstacle({ Name = "BlankObstacle", X = ScreenCenterX, Y = ScreenCenterY, Group =
			"Combat_Menu", Animation = "GUI\\Graybox\\NativeAspectRatioFrame", Alpha = 0.0 })
			table.insert(letterboxIds, letterboxId)
			SetAlpha({ Id = letterboxId, Fraction = 1.0, Duration = 0.2, EaseIn = 0.0, EaseOut = 1.0 })
		elseif ScreenState.NeedsPillarbox then
			local pillarboxLeftId = CreateScreenObstacle({ Name = "BlankObstacle", X = ScreenState.PillarboxLeftX, Y = ScreenCenterY, ScaleX = ScreenState.PillarboxScaleX, Group = "Combat_Menu", Animation = "GUI\\SideBars_01", Alpha = 0.0 })
			table.insert(letterboxIds, pillarboxLeftId)
			SetAlpha({ Id = pillarboxLeftId, Fraction = 1.0, Duration = 0.2, EaseIn = 0.0, EaseOut = 1.0 })
			FlipHorizontal({ Id = pillarboxLeftId })
			local pillarboxRightId = CreateScreenObstacle({ Name = "BlankObstacle", X = ScreenState.PillarboxRightX, Y = ScreenCenterY, ScaleX = ScreenState.PillarboxScaleX, Group = "Combat_Menu", Animation = "GUI\\SideBars_01", Alpha = 0.0 })
			table.insert(letterboxIds, pillarboxRightId)
			SetAlpha({ Id = pillarboxRightId, Fraction = 1.0, Duration = 0.2, EaseIn = 0.0, EaseOut = 1.0 })
		end

		wait(0.21)

		ScreenAnchors.EphyraMapId = CreateScreenObstacle({ Name = "rectangle01", Group = groupName, X = ScreenCenterX, Y = ScreenCenterY })
		table.insert(idsCreated, ScreenAnchors.EphyraMapId)
		SetAnimation({ Name = usee.MapAnimation, DestinationId = ScreenAnchors.EphyraMapId })
		SetHSV({ Id = ScreenAnchors.EphyraMapId, HSV = { 0, -0.15, 0 }, ValueChangeType = "Add" })

		local exitDoorsIPairs = CollapseTableOrdered(MapState.OfferedExitDoors)
		local attachedCircles = {}
		for index, door in ipairs(exitDoorsIPairs) do
			if not door.SkipUnlock then
				local room = door.Room
				local rawScreenLocation = ObstacleData[usee.Name].ScreenLocations[door.ObjectId]
				if rawScreenLocation ~= nil then
					local screenLocation = { X = rawScreenLocation.X + ScreenCenterNativeOffsetX, Y = rawScreenLocation.Y + ScreenCenterNativeOffsetY }
					local rewardBackingId = CreateScreenObstacle({ Name = "BlankGeoObstacle", Group = groupName, X = screenLocation.X, Y = screenLocation.Y, Scale = 0.6 })
					if room.RewardStoreName == "MetaProgress" then
						SetAnimation({ Name = "RoomRewardAvailable_Back_Meta", DestinationId = rewardBackingId })
					else
						SetAnimation({ Name = "RoomRewardAvailable_Back_Run", DestinationId = rewardBackingId })
					end
					table.insert(attachedCircles, rewardBackingId)

					local rewardIconId = CreateScreenObstacle({ Name = "RoomRewardPreview", Group = groupName, X = screenLocation.X, Y = screenLocation.Y, Scale = 0.6 })
					SetColor({ Id = rewardIconId, Color = { 0, 0, 0, 1 } })
					table.insert(attachedCircles, rewardIconId)
					if HasHeroTraitValue("HiddenRoomReward") then
						SetAnimation({ DestinationId = rewardIconId, Name = "ChaosPreview" })
					elseif room.ChosenRewardType == nil or room.ChosenRewardType == "Story" then
						SetAnimation({ DestinationId = rewardIconId, Name = "StoryPreview", SuppressSounds = true })
					elseif room.ChosenRewardType == "Shop" then
						SetAnimation({ DestinationId = rewardIconId, Name = "ShopPreview", SuppressSounds = true })
					elseif room.ChosenRewardType == "Boon" and room.ForceLootName then
						local previewIcon = LootData[room.ForceLootName].DoorIcon or LootData[room.ForceLootName].Icon
						if room.BoonRaritiesOverride ~= nil and LootData[room.ForceLootName].DoorUpgradedIcon ~= nil then
							previewIcon = LootData[room.ForceLootName].DoorUpgradedIcon
						end
						SetAnimation({ DestinationId = rewardIconId, Name = previewIcon, SuppressSounds = true })
					elseif room.ChosenRewardType == "Devotion" then
						local rewardIconAId = CreateScreenObstacle({ Name = "RoomRewardPreview", Group = groupName, X = screenLocation.X + 12, Y = screenLocation.Y - 11, Scale = 0.6 })
						SetColor({ Id = rewardIconAId, Color = { 0, 0, 0, 1 } })
						SetAnimation({ DestinationId = rewardIconAId, Name = LootData[room.Encounter.LootAName].DoorIcon, SuppressSounds = true })
						table.insert(attachedCircles, rewardIconAId)

						local rewardIconBId = CreateScreenObstacle({ Name = "RoomRewardPreview", Group = groupName, X = screenLocation.X - 12, Y = screenLocation.Y + 11, Scale = 0.6 })
						SetColor({ Id = rewardIconBId, Color = { 0, 0, 0, 1 } })
						SetAnimation({ DestinationId = rewardIconBId, Name = LootData[room.Encounter.LootBName].DoorIcon, SuppressSounds = true })
						table.insert(attachedCircles, rewardIconBId)
					else
						local animName = room.ChosenRewardType
						local lootData = LootData[room.ChosenRewardType]
						if lootData ~= nil then
							animName = lootData.DoorIcon or lootData.Icon or animName
						end
						local consumableData = ConsumableData[room.ChosenRewardType]
						if consumableData ~= nil then
							animName = consumableData.DoorIcon or consumableData.Icon or animName
						end
						SetAnimation({ DestinationId = rewardIconId, Name = animName, SuppressSounds = true })
					end

					local subIcons = {}
					if CurrentRun.PylonRooms and CurrentRun.PylonRooms[room.Name] then
						table.insert(subIcons, "GUI\\Icons\\GhostPack")
					end
					if Contains(room.LegalEncounters, "HealthRestore") then
						table.insert(subIcons, "ExtraLifeHeart")
					end
					if room.HarvestPointsAllowed > 0 then
						table.insert(subIcons, "GatherIcon")
					end
					if room.ShovelPointSuccess and HasAccessToTool("ToolShovel") then
						table.insert(subIcons, "ShovelIcon")
					end
					if room.FishingPointSuccess and HasAccessToTool("ToolFishingRod") then
						table.insert(subIcons, "FishingIcon")
					end
					if room.PickaxePointSuccess and HasAccessToTool("ToolPickaxe") then
						table.insert(subIcons, "PickaxeIcon")
					end
					if room.ExorcismPointSuccess and HasAccessToTool("ToolExorcismBook") then
						table.insert(subIcons, "ExorcismIcon")
					end

					if room.RewardPreviewIcon ~= nil and not HasHeroTraitValue("HiddenRoomReward") then
						table.insert(subIcons, room.RewardPreviewIcon)
					end

					local iconSpacing = 30
					local numSubIcons = #subIcons
					local isoOffset = 0
					if numSubIcons % 2 == 0 then
						isoOffset = isoOffset - (iconSpacing / 2)
					end
					for i, iconName in ipairs(subIcons) do
						local iconId = CreateScreenObstacle({ Name = "BlankGeoObstacle", Group = groupName, X = screenLocation.X, Y = screenLocation.Y + 55, Scale = 0.6 })
						-- local iconId = SpawnObstacle({ Name = "BlankGeoObstacle", Group = groupName })
						local offset = CalcOffset(math.rad(330), isoOffset)
						Attach({ Id = iconId, DestinationId = rewardIconId, OffsetZ = -100, OffsetX = offset.X, OffsetY = offset.Y - 60 })
						SetAnimation({ DestinationId = iconId, Name = iconName })
						isoOffset = isoOffset + iconSpacing
						table.insert(attachedCircles, iconId)
						if IsHorizontallyFlipped({ Id = door.ObjectId }) then
							FlipHorizontal({ Id = iconId })
						end
					end

					if IsHorizontallyFlipped({ Id = door.ObjectId }) then
						local ids = ({ rewardBackingId, rewardIconId })
						if not IsEmpty(ids) then
							FlipHorizontal({ Ids = ids })
						end
					end
				end
			end
		end
		local melScreenLocation = ObstacleData[usee.Name].ScreenLocations[usee.ObjectId]
		ScreenAnchors.MelIconId = nil
		if melScreenLocation ~= nil then
			ScreenAnchors.MelIconId = CreateScreenObstacle({ Name = "rectangle01", Group = groupName, X = melScreenLocation.X + ScreenCenterNativeOffsetX, Y = melScreenLocation.Y + ScreenCenterNativeOffsetY, Scale = 1.5 })
			table.insert(idsCreated, ScreenAnchors.MelIconId)
			SetAnimation({ Name = "Mel_Icon", DestinationId = ScreenAnchors.MelIconId })
		end

		SetAlpha({ Ids = { ScreenAnchors.EphyraZoomBackground }, Fraction = 0.0, Duration = 0.35 })
		PlaySound({ Name = "/Leftovers/World Sounds/MapZoomInShort" })
		wait(0.5)

		local zoomOutTime = 0.5

		ScreenAnchors.EphyraZoomBackground = CreateScreenObstacle({ Name = "rectangle01", Group = groupName, X = ScreenCenterX, Y = ScreenCenterY })
		table.insert(idsCreated, ScreenAnchors.EphyraZoomBackground)
		SetScale({ Ids = { ScreenAnchors.EphyraZoomBackground }, Fraction = 5 })
		SetColor({ Ids = { ScreenAnchors.EphyraZoomBackground }, Color = Color.Black })
		SetAlpha({ Ids = { ScreenAnchors.EphyraZoomBackground }, Fraction = 0, Duration = 0 })

		PlayInteractAnimation(usee.ObjectId)

		--FocusCamera({ Fraction = 0.195, Duration = 1, ZoomType = "Ease" })
		--PanCamera({ Id = 664260, Duration = 1.0, EaseIn = 0.3, EaseOut = 0.3 })

		wait(0.3)
		local notifyName = "ephyraZoomBackIn"
		NotifyOnControlPressed({ Names = { "Use", "Rush", "Shout", "Attack2", "Attack1", "Attack3", "AutoLock" }, Notify = notifyName })
		waitUntil(notifyName)
		PlaySound({ Name = "/Leftovers/World Sounds/MapZoomInShort" })

		--FocusCamera({ Fraction = CurrentRun.CurrentRoom.ZoomFraction * 1.0, Duration = 0.5, ZoomType = "Ease" })
		--PanCamera({ Id = CurrentRun.Hero.ObjectId, Duration = 0.5 })

		Move({ Id = ScreenAnchors.LetterBoxTop, Angle = 90, Distance = 150, EaseIn = 0.99, EaseOut = 1.0, Duration = 0.5 })
		Move({ Id = ScreenAnchors.LetterBoxBottom, Angle = 270, Distance = 150, EaseIn = 0.99, EaseOut = 1.0, Duration = 0.5 })
		SetAlpha({ Ids = { ScreenAnchors.EphyraZoomBackground, ScreenAnchors.MelIconId, ScreenAnchors.EphyraMapId, }, Fraction = 0, Duration = 0.25 })
		SetAlpha({ Ids = attachedCircles, Fraction = 0, Duration = 0.15 })
		SetAlpha({ Ids = letterboxIds, Fraction = 0, Duration = 0.15 })
		Destroy({ Ids = attachedCircles })

		local exitDoorsIPairs = CollapseTableOrdered(MapState.OfferedExitDoors)
		for index, door in ipairs(exitDoorsIPairs) do
			if not door.SkipUnlock then
				SetScale({ Id = door.DoorIconId, Fraction = 1, Duration = 0.15 })
				AddToGroup({ Id = door.DoorIconId, Name = "FX_Standing_Top", DrawGroup = true })
			end
		end

		PanCamera({ Id = CurrentRun.Hero.ObjectId, OffsetY = 0, Duration = 0.65, EaseIn = 0, EaseOut = 0, Retarget = true })
		FocusCamera({ Fraction = CurrentRun.CurrentRoom.ZoomFraction, Duration = 0.65, ZoomType = "Ease" })
		local roomData = RoomData[CurrentRun.CurrentRoom.Name]
		if not roomData.IgnoreClamps then
			local cameraClamps = roomData.CameraClamps or GetDefaultClampIds()
			DebugAssert({ Condition = #cameraClamps ~= 1, Text = "Exactly one camera clamp on a map is non-sensical" })
			SetCameraClamp({ Ids = cameraClamps, SoftClamp = roomData.SoftClamp })
		end
		wait(0.45)

		thread(ShowCombatUI, "EphyraZoomOut")
		--SetAlpha({ Ids = { ScreenAnchors.LetterBoxTop, ScreenAnchors.LetterBoxBottom, }, Fraction = 0, Duration = 0.25 })

		RemoveInputBlock({ Name = "EphyraZoomOut" })

		wait(0.4)
		Destroy({ Ids = { ScreenAnchors.LetterBoxTop, ScreenAnchors.LetterBoxBottom, ScreenAnchors.EphyraZoomBackground, ScreenAnchors.MelIconId, ScreenAnchors.EphyraMapId } })

		wait(0.35)
		SetVulnerable({ Id = CurrentRun.Hero.ObjectId })
		UseableOn({ Id = usee.ObjectId })

		Destroy({ Ids = idsCreated })
		Destroy({ Ids = letterboxIds })
	end

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

			local ineligibleFormat = screen.IneligibleFormat
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
