--Numeraknight Xyz
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    --xyz summon
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,(0x657)),nil,2,nil,nil,nil,nil,false,s.xyzcheck)
    --attach from GY
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetTarget(s.mattg)
    e1:SetOperation(s.matop)
    c:RegisterEffect(e1)
    --negate/banish effect
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(2,{id,1})
    e2:SetCondition(s.negcon)
    e2:SetCost(s.negcost)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)
end

function s.xyzcheck(g,tp,xyz)
	local mg=g:Filter(function(c) return not c:IsHasEffect(511001175) end,nil)
	local sum=mg:GetSum(Card.GetLevel)
	return sum>=10
end

function s.matfilter(c,tp,sg)
    if not c:IsLocation(LOCATION_GRAVE) then return false end
    if sg and sg:GetCount()>0 then
        return c:HasLevel() and c:GetLevel()~=sg:GetFirst():GetLevel()
    end
    return c:HasLevel()
end

function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then return Duel.IsExistingTarget(s.matfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,2,nil,tp,nil) end
    local g=Group.CreateGroup()
    for i=1,2 do
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
        local sg=Duel.SelectTarget(tp,s.matfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,g:GetFirst(),tp,g)
        g:Merge(sg)
    end
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,2,0,0)
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
    if #g>0 then
        Duel.Overlay(c,g)
    end
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return re:IsMonsterEffect() and Duel.IsChainNegatable(ev)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    local og=e:GetHandler():GetOverlayGroup()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVEXYZ)
    local mat=og:Select(tp,1,1,nil)
    Duel.SendtoGrave(mat,REASON_COST)
    e:SetLabelObject(mat:GetFirst())
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local rc=re:GetHandler()
    local mat=e:GetLabelObject()
    if not mat or not rc then return end
    
    local matLevel=0
    local rcLevel=0
    if mat:HasLevel() then matLevel=mat:GetLevel() end
    if rc:HasLevel() then rcLevel=rc:GetLevel() end
    
    if matLevel==0 or matLevel==rcLevel then
        Duel.NegateActivation(ev)
        Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)
    elseif matLevel>rcLevel then
        Duel.NegateActivation(ev)
    elseif matLevel<rcLevel and rc:IsRelateToEffect(re) then
        Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)
    end
end