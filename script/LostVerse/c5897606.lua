--Malum of a Lost Universe
local s,id=GetID()
function s.initial_effect(c)
    --Discard to activate one of the effects
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.discost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsDiscardable() end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return s.thtg(e,tp,eg,ep,ev,re,r,rp,0) or s.granteffecttg(e,tp,eg,ep,ev,re,r,rp,0) end
    if s.thtg(e,tp,eg,ep,ev,re,r,rp,0) and s.granteffecttg(e,tp,eg,ep,ev,re,r,rp,0) then
        local op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
        e:SetLabel(op)
    elseif s.thtg(e,tp,eg,ep,ev,re,r,rp,0) then
        e:SetLabel(0)
    else
        e:SetLabel(1)
    end
    if e:GetLabel()==0 then
        s.thtg(e,tp,eg,ep,ev,re,r,rp,1)
    else
        s.granteffecttg(e,tp,eg,ep,ev,re,r,rp,1)
    end
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    if e:GetLabel()==0 then
        s.thop(e,tp,eg,ep,ev,re,r,rp)
    else
        s.granteffectop(e,tp,eg,ep,ev,re,r,rp)
    end
end

function s.thfilter(c)
    return c:IsSetCard(0x5bc) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

function s.gfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_NORMAL) and c:IsSetCard(0x5bc)
end

function s.granteffecttg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.gfilter,tp,LOCATION_MZONE,0,1,nil) end
end

function s.granteffectop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local tc=Duel.SelectMatchingCard(tp,s.gfilter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
    if tc then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetDescription(aux.Stringid(id,2))
        e1:SetCategory(CATEGORY_CONTROL)
        e1:SetType(EFFECT_TYPE_IGNITION)
        e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
        e1:SetRange(LOCATION_MZONE)
        e1:SetCountLimit(1)
        e1:SetTarget(s.ctrltg)
        e1:SetOperation(s.ctrlop)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
end

function s.ctrlfilter(c)
    return c:IsControlerCanBeChanged()
end

function s.ctrltg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.ctrlfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.ctrlfilter,tp,0,LOCATION_MZONE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
    local g=Duel.SelectTarget(tp,s.ctrlfilter,tp,0,LOCATION_MZONE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end

function s.ctrlop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.GetControl(tc,tp)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CHANGE_CODE)
        e1:SetValue(79000000) --Remnant of a Lost Universe
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
end
