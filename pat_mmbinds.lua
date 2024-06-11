Binds = {}

function Binds.sizeIncrease()
  changeSize(1, holdingAltKey())
end

function Binds.sizeDecrease()
  changeSize(-1, holdingAltKey())
end

function Binds.toggleLiquid()
  local mm = getMM()
  if not mm then
    return
  end

  if not mm.parameters.pat_liquidUnlocked then
    queueMessage("liquidLocked")
    return
  end

  mm.parameters.canCollectLiquid = not mm.parameters.canCollectLiquid

  setMM(mm)
  queueMessage(mm.parameters.canCollectLiquid and "liquidEnabled" or "liquidDisabled")
end

function Binds.toggleTiles()
  local mm = getMM()
  if not mm then
    return
  end

  if mm.parameters.tileDamage == 0 then
    mm.parameters.tileDamage = mm.parameters.pat_tileDamage
    queueMessage("tilesEnabled")
  else
    mm.parameters.pat_tileDamage = mm.parameters.tileDamage
    mm.parameters.tileDamage = 0
    queueMessage("tilesDisabled")
  end

  setMM(mm)
end

function changeSize(n, alt)
  local mm = getMM()
  if not mm then
    return
  end

  local key = "blockRadius"
  if alt then
    key = "altBlockRadius"
  end

  local maxRadius = mm.parameters.pat_maxBlockRadius
  local radius = mm.parameters[key]
  local newRadius = math.max(1, math.min(radius + n, maxRadius))

  if newRadius == radius then
    if newRadius == maxRadius then
      queueMessage("maxRadius", maxRadius)
    end
    return
  end

  mm.parameters[key] = newRadius
  setMM(mm)
  queueMessage(key, newRadius)
end

function init()
  if not input or not input.bindDown or not root.assetOrigin or not player.selectedActionBarSlot then
    sb.logWarn("MM Binds requires StarExtensions or OpenStarbound")
    script.setUpdateDelta(0)
    return
  end

  ModConfig = root.assetJson("/pat_mmbinds.sussy")

  local file = ModConfig.mmUpgradeGui
  local file_quickbar = ModConfig.mmUpgradeGui_Quickbar
  if root.assetOrigin(file_quickbar) then
    file = file_quickbar
  end -- buh
  beamaxeUpgrades = root.assetJson(file .. ":upgrades")
end

function update()
  for name, func in pairs(Binds) do
    if input.bindDown("pat_mmbinds", name) then
      func()
      break
    end
  end
end

function queueMessage(key, ...)
  local str = ModConfig.strings[key] or key
  interface.queueMessage(string.format(str, ...), 2.4, 0.8)
end

function getMM()
  local beamaxeItem = player.essentialItem("beamaxe")
  if not beamaxeItem or root.itemType(beamaxeItem.name) ~= "beamminingtool" then
    return
  end
  local params = beamaxeItem.parameters

  if not params.blockRadius or not params.tileDamage or not params.canCollectLiquid then
    local defaults = root.itemConfig(beamaxeItem.name).config
    params.blockRadius = params.blockRadius or defaults.blockRadius or 2
    params.altBlockRadius = params.altBlockRadius or defaults.altBlockRadius or 1
    params.tileDamage = params.tileDamage or defaults.tileDamage or 1
    params.canCollectLiquid = params.canCollectLiquid or defaults.canCollectLiquid or false
  end

  local maxBlockRadius = params.blockRadius
  local liquidUnlocked = params.pat_liquidUnlocked or params.canCollectLiquid

  if params.upgrades then
    for _, name in ipairs(params.upgrades) do
      local upgrade = beamaxeUpgrades[name]

      if upgrade and upgrade.setItemParameters then
        local uParams = upgrade.setItemParameters

        if uParams.blockRadius then
          maxBlockRadius = math.max(maxBlockRadius, uParams.blockRadius)
        end

        if not liquidUnlocked and uParams.canCollectLiquid then
          liquidUnlocked = true
        end
      end
    end
  end

  if maxBlockRadius ~= params.pat_maxBlockRadius then
    maxBlockRadius = math.max(params.pat_maxBlockRadius or 0, maxBlockRadius)
    params.pat_maxBlockRadius = maxBlockRadius
  end

  if not params.pat_liquidUnlocked and liquidUnlocked then
    params.pat_liquidUnlocked = true
  end

  return beamaxeItem
end

function setMM(beamaxeItem)
  player.giveEssentialItem("beamaxe", beamaxeItem)
end

function holdingAltKey()
  return input.bind("pat_mmbinds", "altModifier")
end
