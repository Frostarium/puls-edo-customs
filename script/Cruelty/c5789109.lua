--Atakhan, the Cruel and Bound
local s,id=GetID()
function s.initial_effect(c)
    	c:EnableReviveLimit()
	--to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--when tributed draw 2
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_RELEASE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
    --Unaffected by cards' effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_UNCOPYABLE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetValue(s.immval)
	c:RegisterEffect(e3)
	--Reduce level/rank and clear opponent's Link Monsters
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
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsRitualSummoned()
end
function s.thfilter(c)
	return c:IsSetCard(0x67e) and c:IsAbleToHand()
end
function s.tdfilter(c,tp)
	return c:IsAbleToDeck() and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,c) and c:IsSetCard(0x67e)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.tdfilter(chkc) and chkc~=c end
	if chk==0 then return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE,0,1,c,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,1,c,tp)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) then return end
	if Duel.SendtoDeck(tc,tp,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 then return end
	if not Duel.GetOperatedGroup():GetFirst():IsLocation(LOCATION_DECK|LOCATION_EXTRA) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.BreakEffect()
		Duel.SendtoHand(g,tp,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
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
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.lrfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.lrfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.lrfilter,tp,0,LOCATION_MZONE,1,1,nil)
end
function s.lrop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) then return end
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
		local g=Duel.GetMatchingGroup(Card.IsLinkMonster,tp,0,LOCATION_MZONE,nil)
		if #g>0 then
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	end
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end