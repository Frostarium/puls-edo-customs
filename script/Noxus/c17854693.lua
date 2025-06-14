--Khatash-Li
local s,id=GetID()
function s.initial_effect(c)
    --Battle effect: Negate opponent's monster effects when 0x1735 monster battles
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_DISABLE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(0,LOCATION_MZONE)
    e1:SetCondition(s.discon)
    e1:SetTarget(s.distg)
    c:RegisterEffect(e1)
    
    --Special summon from hand/GY
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_HAND+LOCATION_GRAVE)
    e2:SetCountLimit(1,id)
    e2:SetCost(s.spcost)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
    
    --Negate and destroy when destroyed
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_DESTROYED)
    e3:SetCountLimit(1,{id,1})
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)
end

function s.discon(e)
    return Duel.GetAttacker() and Duel.GetAttackTarget() and 
           ((Duel.GetAttacker():IsSetCard(0x1735) and Duel.GetAttacker():IsControler(e:GetHandlerPlayer())) or
            (Duel.GetAttackTarget() and Duel.GetAttackTarget():IsSetCard(0x1735) and Duel.GetAttackTarget():IsControler(e:GetHandlerPlayer())))
end

function s.distg(e,c)
    local tp=e:GetHandlerPlayer()
    return c:IsControler(1-tp) and c:IsType(TYPE_MONSTER) and 
           ((Duel.GetAttacker() and c==Duel.GetAttacker()) or (Duel.GetAttackTarget() and c==Duel.GetAttackTarget()))
end

function s.costfilter(c)
    return c:IsDestructable()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_ONFIELD,0,1,nil) end
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
        local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
        if #g>0 then
            Duel.Destroy(g,REASON_EFFECT)
        end
    end
end

function s.negfilter(c)
    return c:IsFaceup() and not c:IsDisabled()
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.negfilter,tp,0,LOCATION_ONFIELD,1,nil) end
    local g=Duel.GetMatchingGroup(s.negfilter,tp,0,LOCATION_ONFIELD,nil)
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,g,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
    local g=Duel.SelectMatchingCard(tp,s.negfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
    if #g>0 then
        local tc=g:GetFirst()
        Duel.NegateActivation(tc)
        if tc:IsRelateToEffect(e) then
            Duel.Destroy(tc,REASON_EFFECT)
        end
    end
end
