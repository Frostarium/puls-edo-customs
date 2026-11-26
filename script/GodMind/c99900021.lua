--GodMind Supervisor
--If this card is Normal or Special Summoned, or sent to the GY or banished: select 1 other "GodMind" monster in your Deck,
--then choose to Special Summon it, add it to your hand, send it to the GY, or banish it.
--You can only use this effect of "GodMind Supervisor" once per turn.
local s,id=GetID()
local SET_GODMIND=0x1650
function s.initial_effect(c)
	--when Normal Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--when Special Summoned
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
	--when sent to the GY
	local e3=e1:Clone()
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e3:SetCode(EVENT_TO_GRAVE)
	c:RegisterEffect(e3)
	--when banished
	local e4=e3:Clone()
	e4:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e4)
end
local LOC=LOCATION_DECK
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
--Effect that "GodMind Shi'arWare" / "GodMind Processor 10² Shi'arWare" can borrow (see s.efflist in c99900015.lua and c99900020.lua)
s.apply_effects={
	{desc=aux.Stringid(id,0),category=CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_TOGRAVE+CATEGORY_REMOVE,property=EFFECT_FLAG_DELAY,
		target=s.target,operation=s.operation},
}
