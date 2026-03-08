--Atakhan, the Cruel and Ruinous
local s,id=GetID()
function s.initial_effect(c)
        --Unaffected by cards' effects
        	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.lvlcon)
	e1:SetTarget(s.lvltg)
	e1:SetOperation(s.lvlop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_UNCOPYABLE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetValue(s.immval)
	c:RegisterEffect(e3)
    local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetCountLimit(1,{id,1})
	e4:SetCondition(function() return Duel.IsMainPhase() or Duel.IsBattlePhase() end)
	e4:SetRange(LOCATION_MZONE)
	e4:SetHintTiming(0,TIMING_MAIN_END|TIMING_BATTLE_START|TIMING_BATTLE_END|TIMINGS_CHECK_MONSTER)
	e4:SetTarget(s.lrtg)
	e4:SetOperation(s.lrop)
	c:RegisterEffect(e4)
end
function s.immval(e,te)
	if not (te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActivated()) then return false end
	local tc=te:GetHandler()
	local lv=e:GetHandler():GetLevel()
	if tc:HasLevel() then
		return tc:GetLevel()<lv
	elseif tc:HasRank() then
		return tc:GetRank()<lv
	end
	return false
end
function s.lrfilter(c)
	return (c:HasLevel() or c:HasRank()) and c:IsFaceup()
end
function s.lrtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.HasLevel,1),tp,0,LOCATION_MZONE,1,nil)
end
function s.lrop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.HasLevel,tp,0,LOCATION_MZONE,1,nil)
	for tc in aux.Next(g) do
	-- Check if opponent controlled any Link Monsters at activation
	local haslinkmon=Duel.IsExistingMatchingCard(Card.IsLinkMonster,tp,0,LOCATION_MZONE,1,nil)
	-- Reduce level or rank by 6
	local lv=0
	if tc:HasLevel() then
		lv=tc:GetLevel()
	elseif tc:HasRank() then
		lv=tc:GetRank()
	end
	if lv>0 then
		local new_lv=lv-6
		if new_lv<1 then
			Duel.SendtoGrave(tc,REASON_EFFECT)
		else
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			if tc:HasLevel() then
				e1:SetCode(EFFECT_UPDATE_LEVEL)
			else
				e1:SetCode(EFFECT_UPDATE_RANK)
			end
			e1:SetValue(-6)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			tc:RegisterEffect(e1)
		end
	end
	-- If opponent controlled Link Monsters, send all their Link Monsters to GY
	if haslinkmon then
		local g=Duel.GetMatchingGroup(aux.FaceupFilter,tp,0,LOCATION_MZONE,nil)
		if #g>0 then
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	end
end
end
function s.lvlcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
end
function s.lvltg(e,tp,eg,ep,ev,re,r,rp,chk)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.HasLevel,1),tp,0,LOCATION_MZONE,1,nil)
end
-- s.op: Reduces opponent's monsters' levels by 4; if reduced below 1, send to GY
function s.lvlop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.HasLevel,tp,0,LOCATION_MZONE,1,nil)
    for tc in aux.Next(g) do
        if tc:IsLevelAbove(1) then
            local lv=tc:GetLevel()
            local new_lv=lv-3
            if new_lv<1 then
                Duel.SendtoGrave(tc,REASON_EFFECT)
            else
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_UPDATE_LEVEL)
                e1:SetValue(-3)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
                tc:RegisterEffect(e1)
            end
        end
    end
end