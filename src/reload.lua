---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

-- this file will be reloaded if it changes during gameplay,
-- 	so only assign to values or define things here.

if config.DoorIndicators.Enabled then

	function CreateDoorRewardPreview_override(exitDoor, chosenRewardType, chosenLootName, index, args)
		local room = exitDoor.Room
		args = args or {}

		if exitDoor.HideRewardPreview or room.HideRewardPreview then
			return
		end

		if not args.SkipCageRewards and room.CageRewards ~= nil and chosenRewardType == nil then
			for index, cageReward in ipairs(room.CageRewards) do
				CreateDoorRewardPreview(exitDoor, cageReward.RewardType, cageReward.ForceLootName, index,
					{ SkipCageRewards = true, })
			end
			return
		end

		chosenRewardType = chosenRewardType or room.ChosenRewardType
		chosenLootName = chosenLootName or room.ForceLootName

		local doorIconOffsetX = exitDoor.RewardPreviewOffsetX or 0
		local doorIconOffsetY = exitDoor.RewardPreviewOffsetY or 0
		local doorIconOffsetZ = exitDoor.RewardPreviewOffsetZ or 130

		local doorIconIsometricShiftX = -6
		local doorIconIsometricShiftZ = -3

		index = index or 1

		doorIconOffsetZ = doorIconOffsetZ + ((index - 1) * 180)

		if IsHorizontallyFlipped({ Id = exitDoor.ObjectId }) then
			doorIconOffsetX = doorIconOffsetX * -1
			doorIconIsometricShiftX = doorIconIsometricShiftX * -1
		end
		exitDoor.AdditionalIcons = exitDoor.AdditionalIcons or {}

		exitDoor.RewardPreviewBackingIds = exitDoor.RewardPreviewBackingIds or {}
		local backingId = nil
		if args.ReUseIds then
			backingId = exitDoor.RewardPreviewBackingIds[index]
		else
			backingId = SpawnObstacle({ Name = "BlankGeoObstacle", Group = "Combat_UI_World" })
			SetThingProperty({ Property = "AllowDrawableCache", Value = false, DestinationId = backingId })
			table.insert(exitDoor.RewardPreviewBackingIds, backingId)
			SetAlpha({ Id = backingId, Fraction = 0.0, Duration = 0.0 })
			SetAlpha({ Id = backingId, Fraction = 1.0, Duration = 0.1 })
			Attach({ Id = backingId, DestinationId = exitDoor.ObjectId, OffsetZ = doorIconOffsetZ, OffsetY = doorIconOffsetY, OffsetX = doorIconOffsetX })
		end
		if (exitDoor.RewardStoreName or exitDoor.Room.RewardStoreName) == "MetaProgress" then
			SetAnimation({ Name = "RoomRewardAvailable_Back_Meta", DestinationId = backingId })
		else
			SetAnimation({ Name = "RoomRewardAvailable_Back_Run", DestinationId = backingId })
		end

		exitDoor.RewardPreviewIconIds = exitDoor.RewardPreviewIconIds or {}
		local doorIconId = nil
		if args.ReUseIds then
			doorIconId = exitDoor.RewardPreviewIconIds[index]
		else
			doorIconId = SpawnObstacle({
				Name = "RoomRewardPreview",
				Group = "Combat_UI",
				DestinationId = exitDoor.ObjectId,
				OffsetY = doorIconOffsetY,
				OffsetX = doorIconOffsetX + doorIconIsometricShiftX,
				OffsetZ = doorIconOffsetZ + doorIconIsometricShiftZ
			})
			SetAlpha({ Id = doorIconId, Fraction = 0.0, Duration = 0.0 })
			SetAlpha({ Id = doorIconId, Fraction = 1.0, Duration = 0.1 })
			table.insert(exitDoor.RewardPreviewIconIds, doorIconId)
		end

		local rewardHidden = false
		if room.RewardPreviewOverride ~= nil then
			exitDoor.RewardPreviewAnimName = room.RewardPreviewOverride
			SetAnimation({ DestinationId = doorIconId, Name = exitDoor.RewardPreviewAnimName })
		elseif room.NextRoomSet then
			exitDoor.RewardPreviewAnimName = room.ExitPreviewAnim or "ExitPreview"
			SetAnimation({ DestinationId = doorIconId, Name = exitDoor.RewardPreviewAnimName })
		elseif HasHeroTraitValue("HiddenRoomReward") then
			exitDoor.RewardPreviewAnimName = "ChaosPreview"
			SetAnimation({ DestinationId = doorIconId, Name = exitDoor.RewardPreviewAnimName })
			rewardHidden = true
		elseif chosenRewardType == nil or chosenRewardType == "Story" then
			if chosenRewardType ~= "Story" and exitDoor.DefaultRewardPreviewOverride then
				exitDoor.RewardPreviewAnimName = exitDoor.DefaultRewardPreviewOverride
			else
				exitDoor.RewardPreviewAnimName = "StoryPreview"
			end
			SetAnimation({ DestinationId = doorIconId, Name = exitDoor.RewardPreviewAnimName })
		elseif chosenRewardType == "Shop" then
			exitDoor.RewardPreviewAnimName = "ShopPreview"
			SetAnimation({ DestinationId = doorIconId, Name = exitDoor.RewardPreviewAnimName })
		elseif chosenRewardType == "Boon" and chosenLootName ~= nil then
			local lootData = LootData[chosenLootName]
			DebugAssert({ Condition = lootData ~= nil, Text = "Unable to find LootData for " .. chosenLootName })
			exitDoor.RewardPreviewAnimName = lootData.DoorIcon or lootData.Icon
			if exitDoor.Room.BoonRaritiesOverride ~= nil and lootData.DoorUpgradedIcon ~= nil then
				exitDoor.RewardPreviewAnimName = lootData.DoorUpgradedIcon
			end
			SetAnimation({ DestinationId = doorIconId, Name = exitDoor.RewardPreviewAnimName })
		elseif chosenRewardType == "Devotion" then
			--DebugPrint({ Text = "room.Encounter.LootAName = "..tostring(room.Encounter.LootAName) })
			--DebugPrint({ Text = "room.Encounter.LootBName = "..tostring(room.Encounter.LootBName) })
			exitDoor.RewardPreviewAnimName = "Devotion"

			local doorAIconId = SpawnObstacle({
				Name = "RoomRewardPreview",
				Group = "Combat_UI",
				DestinationId = exitDoor.ObjectId,
				OffsetX = doorIconOffsetX + doorIconIsometricShiftX + 18,
				OffsetY = doorIconOffsetY,
				OffsetZ = doorIconOffsetZ + doorIconIsometricShiftZ + 20
			})
			local animName = LootData[room.Encounter.LootAName].DoorIcon
			SetAnimation({ DestinationId = doorAIconId, Name = animName })
			SetScale({ Id = doorAIconId, Fraction = 0.85 })
			exitDoor.AdditionalIcons[animName] = doorAIconId
			SetColor({ Id = doorAIconId, Color = { 1.0, 1.0, 1.0, 0 }, Duration = 0 })
			SetColor({ Id = doorAIconId, Color = { 0, 0, 0, 1 }, Duration = 0.2 })

			local doorBIconId = SpawnObstacle({
				Name = "RoomRewardPreview",
				Group = "Combat_UI",
				DestinationId = exitDoor.ObjectId,
				OffsetX = doorIconOffsetX + doorIconIsometricShiftX - 18,
				OffsetY = doorIconOffsetY,
				OffsetZ = doorIconOffsetZ + doorIconIsometricShiftZ - 20
			})
			animName = LootData[room.Encounter.LootBName].DoorIcon
			SetAnimation({ DestinationId = doorBIconId, Name = animName })
			SetScale({ Id = doorBIconId, Fraction = 0.85 })
			exitDoor.AdditionalIcons[animName] = doorBIconId
			SetColor({ Id = doorBIconId, Color = { 1.0, 1.0, 1.0, 0 }, Duration = 0 })
			SetColor({ Id = doorBIconId, Color = { 0, 0, 0, 1 }, Duration = 0.2 })
		else
			local animName = chosenRewardType
			local lootData = LootData[chosenRewardType]
			if lootData ~= nil then
				animName = lootData.DoorIcon or lootData.Icon or animName
			end
			local consumableData = ConsumableData[chosenRewardType]
			if consumableData ~= nil then
				animName = consumableData.DoorIcon or consumableData.Icon or animName
			end
			exitDoor.RewardPreviewAnimName = animName
			SetAnimation({ DestinationId = doorIconId, Name = exitDoor.RewardPreviewAnimName })
		end

		if exitDoor.RewardPreviewAnimName ~= nil then
			MapState.OfferedRewardPreviewTypes[exitDoor.RewardPreviewAnimName] = true
		end

		local subIcons = {}

		if not rewardHidden then
			local itemData = ConsumableData[chosenRewardType]
			if itemData ~= nil and itemData.AddResources ~= nil then
				for resourceName, amount in pairs(itemData.AddResources) do
					if HasPinWithResource(resourceName) then
						table.insert(subIcons, "RoomRewardSubIcon_ForgetMeNot")
					end
				end
			end
		end

		local iconZ = 50
		local iconGroup = "Combat_UI_World"
		-- MOD START
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
		if CurrentRun.PylonRooms and CurrentRun.PylonRooms[room.Name] then
			table.insert(subIcons, "GUI\\Icons\\GhostPack")
		end
		-- MOD END
		if room.RewardPreviewIcon ~= nil and not HasHeroTraitValue("HiddenRoomReward") then
			table.insert(subIcons, room.RewardPreviewIcon)
		end
		local hasQuestIcon = false
		local encountersChecked = {}
		if room.LegalEncounters ~= nil then
			for k, encounterName in pairs(room.LegalEncounters) do
				if not encountersChecked[encounterName] and not GameState.EncountersCompletedCache[encounterName] and HasActiveQuestForName(encounterName) then
					hasQuestIcon = true
					break
				end
				encountersChecked[encounterName] = true
			end
		end
		if not hasQuestIcon and room.ForceLootName ~= nil then
			local questTraitName = room.ForceLootName
			if SpellData[questTraitName] ~= nil then
				questTraitName = SpellData[questTraitName].TraitName or questTraitName
			end
			if not GameState.TraitsTaken[questTraitName] and HasActiveQuestForName(questTraitName) then
				hasQuestIcon = true
			end
		end
		if hasQuestIcon then
			table.insert(subIcons, "RoomRewardSubIcon_FatedList")
		end

		local iconSpacing = 60
		local numSubIcons = #subIcons
		local isoOffset = 0
		if numSubIcons % 2 == 0 then
			isoOffset = isoOffset - (iconSpacing / 2)
		end
		for i, iconName in ipairs(subIcons) do
			AddDoorInfoIcon({ Door = exitDoor, DoorIconId = doorIconId, Group = iconGroup, IsoOffset = isoOffset, Name = iconName, ReUseIds = args.ReUseIds })
			isoOffset = isoOffset + iconSpacing
		end

		if not args.ReUseIds and IsHorizontallyFlipped({ Id = exitDoor.ObjectId }) then
			local ids = { doorIconId, backingId }
			FlipHorizontal({ Ids = ids })
			FlipHorizontal({ Ids = GetAllValues(exitDoor.AdditionalIcons) })
		end

		PlaySound({ Id = exitDoor.ObjectId, Name = "/Leftovers/SFX/DoorStateChangeRewardAppearance" })
	end

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
end
