--Shinryu Verus
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Must be Special Summoned by specific card
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(aux.FALSE)
	c:RegisterEffect(e1)
	
	--Banish face-down
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)
	
	--Return to Extra Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.tdtg)
	e3:SetOperation(s.tdop)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e4:SetValue(1)
	c:RegisterEffect(e4)
	local e5=Effect.CreateEffect(c)
	e5:SetCode(EFFECT_REFLECT_BATTLE_DAMAGE)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetValue(1)
	c:RegisterEffect(e5)
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil,tp,POS_FACEDOWN) end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thfilter(c)
	return c:IsSetCard(0x456) and c:IsAbleToHand()
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil,tp,POS_FACEDOWN)
    if #g>0 and Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)>0 then
        local sg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
        if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local tg=sg:Select(tp,1,1,nil)
            Duel.SendtoHand(tg,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,tg)
        end
    end
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end

function s.spfilter(c,e,tp)
	return c:IsCode(810000144) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_REMOVED,0,nil,e,tp)
		if #g>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=g:Select(tp,1,1,nil)
			Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end