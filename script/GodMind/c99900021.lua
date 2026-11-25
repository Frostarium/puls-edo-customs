--GodMind Supervisor
--Ignition effect while it is on the field, or when it is sent to the GY or banished: select 1 other "GodMind" monster from your
--hand, Deck, GY or banishment, then choose to Special Summon it, add it to your hand, send it to the GY, or banish it.
--You can only use this effect of "GodMind Supervisor" once per turn.
local s,id=GetID()
local SET_GODMIND=0x1650
function s.initial_effect(c)
	--on the field (Ignition)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--when sent to the GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
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
local LOC=LOCATION_HAND|LOCATION_DECK|LOCATION_GRAVE|LOCATION_REMOVED
--pick 1 other "GodMind" monster first, then choose what to do with it: Special Summon / add to hand / send to the GY / banish
function s.canspsummon(c,e,tp)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.pickfilter(c,e,tp)
	return c:IsSetCard(SET_GODMIND) and c:IsMonster() and (not c:IsLocation(LOCATION_REMOVED) or c:IsFaceup())
		and (s.canspsummon(c,e,tp) or c:IsAbleToHand() or c:IsAbleToGrave() or c:IsAbleToRemove())
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.pickfilter,tp,LOC,0,1,e:GetHandler(),e,tp) end
	e:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_TOGRAVE+CATEGORY_REMOVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOC)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOC)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOC)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOC)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
	local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.pickfilter),tp,LOC,0,1,1,e:GetHandler(),e,tp):GetFirst()
	if not tc then return end
	local op=Duel.SelectEffect(tp,
		{s.canspsummon(tc,e,tp),aux.Stringid(id,1)},
		{tc:IsAbleToHand(),aux.Stringid(id,2)},
		{tc:IsAbleToGrave(),aux.Stringid(id,3)},
		{tc:IsAbleToRemove(),aux.Stringid(id,4)})
	if op==1 then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	elseif op==2 then
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,tc)
		end
	elseif op==3 then
		Duel.SendtoGrave(tc,REASON_EFFECT)
	else
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end
