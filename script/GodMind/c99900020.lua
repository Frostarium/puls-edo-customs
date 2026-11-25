--GodMind Ambassador
--Ignition effect while it is on the field, or when it is sent to the GY or banished: select 1 "GodMind" card in your Deck,
--then choose to add it to your hand, send it to the GY, or banish it.
--You can only use this effect of "GodMind Ambassador" once per turn.
local s,id=GetID()
local SET_GODMIND=0x1650
function s.initial_effect(c)
	--on the field (Ignition)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--when sent to the GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
	--when banished
	local e3=e2:Clone()
	e3:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e3)
end
--pick 1 "GodMind" card in your Deck first, then choose what to do with it: add it to your hand / send it to the GY / banish it
function s.pickfilter(c)
	return c:IsSetCard(SET_GODMIND) and (c:IsAbleToHand() or c:IsAbleToGrave() or c:IsAbleToRemove())
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.pickfilter,tp,LOCATION_DECK,0,1,nil) end
	e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE+CATEGORY_REMOVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_DECK)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
	local tc=Duel.SelectMatchingCard(tp,s.pickfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
	if not tc then return end
	local op=Duel.SelectEffect(tp,
		{tc:IsAbleToHand(),aux.Stringid(id,1)},
		{tc:IsAbleToGrave(),aux.Stringid(id,2)},
		{tc:IsAbleToRemove(),aux.Stringid(id,3)})
	if op==1 then
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,tc)
		end
	elseif op==2 then
		Duel.SendtoGrave(tc,REASON_EFFECT)
	else
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end
