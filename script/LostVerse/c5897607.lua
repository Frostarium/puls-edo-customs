--Chaos of a Lost Universe
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
    if chk==0 then return s.acttg(e,tp,eg,ep,ev,re,r,rp,0) or s.granteffecttg(e,tp,eg,ep,ev,re,r,rp,0) end
    if s.acttg(e,tp,eg,ep,ev,re,r,rp,0) and s.granteffecttg(e,tp,eg,ep,ev,re,r,rp,0) then
        local op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
        e:SetLabel(op)
    elseif s.acttg(e,tp,eg,ep,ev,re,r,rp,0) then
        e:SetLabel(0)
    else
        e:SetLabel(1)
    end
    if e:GetLabel()==0 then
        s.acttg(e,tp,eg,ep,ev,re,r,rp,1)
    else
        s.granteffecttg(e,tp,eg,ep,ev,re,r,rp,1)
    end
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    if e:GetLabel()==0 then
        s.actop(e,tp,eg,ep,ev,re,r,rp)
    else
        s.granteffectop(e,tp,eg,ep,ev,re,r,rp)
    end
end

function s.actfilter(c,tp)
    return c:IsCode(5897604) and c:GetActivateEffect():IsActivatable(tp,true,true)
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.actfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,tp) end
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local tc=Duel.SelectMatchingCard(tp,s.actfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,tp):GetFirst()
    if tc then
        local te=tc:GetActivateEffect()
        if te and te:IsActivatable(tp,true,true) then
            local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
            if fc then
                Duel.SendtoGrave(fc,REASON_RULE)
                Duel.BreakEffect()
            end
            Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
            te:UseCountLimit(tp,1,true)
            local tep=tc:GetControler()
            local cost=te:GetCost()
            if cost then cost(te,tep,eg,ep,ev,re,r,rp,1) end
            Duel.RaiseEvent(tc,4179255,te,0,tp,tp,Duel.GetCurrentChain())
        end
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
        e1:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND)
        e1:SetType(EFFECT_TYPE_IGNITION)
        e1:SetRange(LOCATION_MZONE)
        e1:SetCountLimit(1)
        e1:SetTarget(s.destg)
        e1:SetOperation(s.desop)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsType,tp,0,LOCATION_ONFIELD,1,nil,TYPE_SPELL+TYPE_TRAP) end
    local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_ONFIELD,nil,TYPE_SPELL+TYPE_TRAP)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.thfilter(c)
    return c:IsSetCard(0x5bc) and c:IsAbleToHand()
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_ONFIELD,nil,TYPE_SPELL+TYPE_TRAP)
    if Duel.Destroy(g,REASON_EFFECT)>0 and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil)
        and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
        if #sg>0 then
            Duel.SendtoHand(sg,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,sg)
        end
    end
end
