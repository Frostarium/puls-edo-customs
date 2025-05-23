--Numeraknight 9
local s,id=GetID()
function s.initial_effect(c)
	-- Normal activate (from hand or field)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(function() return Duel.IsMainPhase() end)
	e1:SetCountLimit(1,{id,1})
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- Quick effect (only from field)
	local e2=e1:Clone()
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e2)
	--Send to GY effect
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_NO_TURN_RESET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,0})
	e3:SetTarget(s.gytg)
	e3:SetOperation(s.gyop)
	c:RegisterEffect(e3)
end

function s.costfilter(c,tp,sc,e)
    if not c:HasLevel() then return false end
    local lv1=c:GetLevel()
    local lv2=sc:GetLevel()
    local sumlv=lv1+lv2
    local diflv=math.abs(lv1-lv2)
    return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,sumlv,tp,e)
        or Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,diflv,tp,e)
end

function s.spfilter(c,lv,tp,e)
    return c:IsSetCard(0x657) and c:IsMonster() and c:HasLevel() 
        and c:GetLevel()==lv and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToGraveAsCost() 
        and Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,c,tp,c,e) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,c,tp,c,e)
    local tc=g:GetFirst()
    g:AddCard(c)
    e:SetLabel(tc:GetLevel())
    e:SetLabelObject(c)
    Duel.SendtoGrave(g,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1 end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local lv1=e:GetLabel()
	local lv2=e:GetLabelObject():GetLevel()
	local sumlv=lv1+lv2
	local diflv=math.abs(lv1-lv2)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK,0,nil,sumlv,tp,e)
	local g2=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK,0,nil,diflv,tp,e)
	g:Merge(g2)
	if #g>0 then
		local sg=g:Select(tp,1,1,nil)
		Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
	end
end

function s.tgfilter(c,tp)
    if not c:IsFaceup() then return false end
    if not c:HasLevel() then return true end
    return Duel.IsExistingMatchingCard(function(mc) return mc:IsFaceup() and mc:HasLevel() and mc:GetLevel()>c:GetLevel() end,
        tp,LOCATION_MZONE,0,1,nil)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.tgfilter(chkc,tp) end
    if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,0,LOCATION_MZONE,1,nil,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectTarget(tp,s.tgfilter,tp,0,LOCATION_MZONE,1,1,nil,tp)
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) then
        Duel.SendtoGrave(tc,REASON_EFFECT)
    end
end