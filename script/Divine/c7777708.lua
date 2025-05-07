--Subjugator of the Divine
local s,id=GetID()
function s.initial_effect(c)
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DIVINE),11,2)
    c:EnableReviveLimit()   
    c:SetSPSummonOnce(id)
    
    --Cannot be targeted by opponent's card effects
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e1:SetValue(aux.tgoval)
    e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ) end)
    c:RegisterEffect(e1)

    --Annihilation effect
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,0})
    e2:SetCost(s.ancost)
    e2:SetTarget(s.antg)
    e2:SetOperation(s.anop)
    c:RegisterEffect(e2)

    --Non-targeting annihilation
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_REMOVE)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetCountLimit(1,{id,1})
    e3:SetRange(LOCATION_MZONE)
    e3:SetCost(s.ntcost)
    e3:SetOperation(s.ntop)
    c:RegisterEffect(e3)
end

--cost
function s.ancost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end

--target
function s.antg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
    if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

--operation
function s.anop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        local code=tc:GetOriginalCode()
        local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD+LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED):Filter(Card.IsOriginalCode,nil,code)
        if #g>0 then
            g:ForEach(function(c) c:ResetEffect(RESETS_STANDARD,RESET_EVENT) end)
            Duel.RemoveCards(g)
        end
    end
end

--non-targeting cost
function s.ntcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

--non-targeting operation
function s.ntop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
    if #g>0 then
        g:GetFirst():ResetEffect(RESETS_STANDARD,RESET_EVENT)
        Duel.RemoveCards(g)
    end
end