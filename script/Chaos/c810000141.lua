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
	
	--Destroy and search
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
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
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    local b1=Duel.IsExistingMatchingCard(Card.IsType,tp,0,LOCATION_ONFIELD,1,nil,TYPE_SPELL+TYPE_TRAP)
    local b2=Duel.IsExistingMatchingCard(Card.IsType,tp,0,LOCATION_MZONE,1,nil,TYPE_MONSTER)
    if chk==0 then return b1 or b2 end
    local ops={}
    local opval={}
    if b1 then
        table.insert(ops,aux.Stringid(id,2))
        table.insert(opval,0)
    end
    if b2 then
        table.insert(ops,aux.Stringid(id,3))
        table.insert(opval,1)
    end
    local op=opval[Duel.SelectOption(tp,table.unpack(ops))+1]
    e:SetLabel(op)
    local g
    if op==0 then
        g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_ONFIELD,nil,TYPE_SPELL+TYPE_TRAP)
    else
        g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_MONSTER)
    end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thfilter(c)
	return c:IsSetCard(0x456) and c:IsAbleToHand()
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g
	if e:GetLabel()==0 then
		g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_ONFIELD,nil,TYPE_SPELL+TYPE_TRAP)
	else
		g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_MONSTER)
	end
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
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