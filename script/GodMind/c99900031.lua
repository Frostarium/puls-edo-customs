--GodMind Casualties (was "GodMind Hotfix" until 2026-11-22)
--Counter Trap. When your opponent activates a monster effect, or a Spell/Trap Card, while you control 3 or more "GodMind" monsters:
--negate the activation, and if you do, shuffle that card into the Deck, then banish all other copies of that card from your opponent's field, hand, Deck, Extra Deck, and GY.
--If this card is in your GY: you can banish 1 other "GodMind" card from your GY; shuffle this card into the Deck.
--You can only use each effect of "GodMind Casualties" once per turn.
local s,id=GetID()
local SET_GODMIND=0x1650
local EXTRA_TYPES=TYPE_FUSION|TYPE_SYNCHRO|TYPE_XYZ|TYPE_LINK
local COPY_LOCS=LOCATION_ONFIELD|LOCATION_HAND|LOCATION_DECK|LOCATION_EXTRA|LOCATION_GRAVE
function s.initial_effect(c)
	--Negate the activation, banish all other copies, shuffle that card into the Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--If this card is in your GY: banish 1 other "GodMind" card from your GY; shuffle this card into the Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.tdcost)
	e2:SetTarget(s.tdtg)
	e2:SetOperation(s.tdop)
	c:RegisterEffect(e2)
end
function s.gmfilter(c)
	return c:IsFaceup() and c:IsMonster() and c:IsSetCard(SET_GODMIND)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not Duel.IsChainNegatable(ev) then return false end
	if not (re:IsMonsterEffect() or re:IsHasType(EFFECT_TYPE_ACTIVATE)) then return false end
	return Duel.IsExistingMatchingCard(s.gmfilter,tp,LOCATION_MZONE,0,3,nil)
end
function s.rmfilter(c,code,rc)
	return c~=rc and c:IsCode(code) and c:IsAbleToRemove()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local rc=re:GetHandler()
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	local g=Duel.GetMatchingGroup(s.rmfilter,tp,0,COPY_LOCS,rc,rc:GetCode(),rc)
	if #g>0 then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
	end
	if s.canshuffle(rc,re) then
		Duel.SetOperationInfo(0,CATEGORY_TODECK,rc,1,0,0)
	end
end
--can the negated card still be shuffled into the Deck? On the field it must still be related to the negated effect (like the official
--"negate, then shuffle" cards); a monster that was discarded or sent as a cost is already in the GY / hand / banishment, so it is shuffled from there.
function s.canshuffle(rc,re)
	if rc:IsOnField() then return rc:IsRelateToEffect(re) end
	return rc:IsLocation(LOCATION_HAND|LOCATION_GRAVE|LOCATION_REMOVED)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	local code=rc:GetCode()
	--ORDER MATTERS (error.log 2026-11-24, Infinite Impermanence): Duel.NegateActivation takes an activated Spell/Trap Card out of play
	--(its location becomes 0), after which it is no longer related to the effect and cannot be moved. So the card is checked and
	--shuffled into the Deck FIRST, while it is still on the field and related, and only then is the activation negated.
	--(Negation of the chain link does not need the card to still be there.)
	local shuffled=false
	if s.canshuffle(rc,re) then
		if rc:IsOnField() then rc:CancelToGrave() end
		shuffled=Duel.SendtoDeck(rc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0
	end
	local negated=Duel.NegateActivation(ev)
	if not negated then return end
	local g=Duel.GetMatchingGroup(s.rmfilter,tp,0,COPY_LOCS,rc,code,rc)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end
function s.costfilter(c)
	return c:IsSetCard(SET_GODMIND) and c:IsAbleToRemoveAsCost()
end
function s.tdcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_GRAVE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_GRAVE,0,1,1,e:GetHandler())
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToDeck() end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,0,0)
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end
