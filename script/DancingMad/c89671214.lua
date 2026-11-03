--Kefka Master of the Warring Triad
local s,id=GetID()
local SET_WARRING_TRIAD=0x1613
local CARD_STATUE_OF_THE_GODS=89671213
s.listed_names={CARD_STATUE_OF_THE_GODS}
function s.initial_effect(c)
	--If you control a "Warring Triad" card: Special Summon this card from your hand, and if you do, you can place 1 "Statue of the Gods" from your Deck in your Field Zone
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,0})
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--Quick Effect, only during your opponent's turn: target 1 monster in your opponent's GY; it gains an effect that negates the next card or effect they activate
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCondition(s.condition)
	e2:SetTarget(s.target)
	e2:SetOperation(s.activate)
	c:RegisterEffect(e2)
end
--Special Summon + Statue
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_WARRING_TRIAD)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_ONFIELD,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_HAND)
end
function s.statuefilter(c)
	return c:IsCode(CARD_STATUE_OF_THE_GODS) and not c:IsForbidden()
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0) then return end
	--optionally place "Statue of the Gods" (it is placed, not activated); it replaces the Field Spell already in your Field Zone
	if not Duel.IsExistingMatchingCard(s.statuefilter,tp,LOCATION_DECK,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local tc=Duel.SelectMatchingCard(tp,s.statuefilter,tp,LOCATION_DECK,0,0,1,nil):GetFirst()
	if not tc then return end
	Duel.BreakEffect()
	local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
	if fc and Duel.SendtoGrave(fc,REASON_RULE)==0 then return end
	Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
end
--negation
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==1-tp
end
function s.tgfilter(c)
	return c:IsMonster() and c:IsAbleToRemove()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(1-tp) and s.tgfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,0,LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.tgfilter,tp,0,LOCATION_GRAVE,1,1,nil)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	--Mandatory Quick Effect: when its owner activates a card or effect, banish this card from the GY, and if you do, negate that activation
	--("Statue of the Gods": if the coin toss for this activation was tails, it Special Summons itself to your field as a Zombie instead of being banished)
	local tails=e:GetHandler():GetFlagEffectLabel(CARD_STATUE_OF_THE_GODS)==Duel.GetCurrentChain()
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_NEGATE)
	--remembers who applied it (the effect belongs to the targeted monster, so its own owner is not reliable): 0 = heads, otherwise your player + 1
	e1:SetLabel(tails and tp+1 or 0)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_F)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_GRAVE)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	--not this effect itself: its own chain link also counts as your opponent activating an effect
	return rp==e:GetHandlerPlayer() and re:GetHandler()~=e:GetHandler() and Duel.IsChainNegatable(ev)
end
--tails: Special Summon itself to the field of the player who applied the effect (not its owner's), if it can
function s.revive(e)
	local c=e:GetHandler()
	local p=e:GetLabel()-1
	return p>=0 and Duel.GetLocationCount(p,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,p,false,false),p
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	if s.revive(e) then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,e:GetLabel()-1,LOCATION_GRAVE)
	else
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,0,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local revive,p=s.revive(e)
	if revive then
		if Duel.SpecialSummonStep(c,0,p,p,false,false,POS_FACEUP) then
			--Zombie
			local e1=Effect.CreateEffect(e:GetOwner())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CHANGE_RACE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetValue(RACE_ZOMBIE)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD)
			c:RegisterEffect(e1)
			Duel.SpecialSummonComplete()
			Duel.NegateActivation(ev)
		else
			Duel.SpecialSummonComplete()
		end
	elseif Duel.Remove(c,POS_FACEUP,REASON_EFFECT)>0 then
		Duel.NegateActivation(ev)
	end
end
