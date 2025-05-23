--Numeraknight 5
local s,id=GetID()
function s.initial_effect(c)
	-- Normal activate (from hand or field)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(function() return Duel.IsMainPhase() end)
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
	--Draw when summoned
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DRAW+CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,0})
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
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

function s.drfilter(c,g)
    if not (c:IsFaceup() and c:HasLevel()) then return false end
    local lv=c:GetLevel()
    return g:IsExists(function(tc) return tc:GetLevel()==lv and tc~=c end,1,c)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    local ct=g:FilterCount(s.drfilter,nil,g)
    if chk==0 then return ct>0 and Duel.IsPlayerCanDraw(tp,ct) end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(ct)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,ct)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
    local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    local ct=g:FilterCount(s.drfilter,nil,g)
    if ct>0 and Duel.Draw(p,ct,REASON_EFFECT)>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
        local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,1,1,nil)
        if #g>0 then
            Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        end
    end
end