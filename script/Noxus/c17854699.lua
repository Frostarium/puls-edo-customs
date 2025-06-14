--Decisive Maneuver
local s,id=GetID()
function s.initial_effect(c)
    --Banish from opponent's GY to negate and destroy
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
    e1:SetCost(s.negcost)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)
    --Set from GY when opponent's card is destroyed
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DESTROYED)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCondition(s.setcon)
    e2:SetCost(s.setcost)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,1,nil)
    Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,nil) end
    local g=Duel.GetMatchingGroup(Card.IsNegatable,tp,0,LOCATION_ONFIELD,nil)
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,g,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    --Restriction
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
    local g=Duel.SelectMatchingCard(tp,Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,1,nil)
    if #g>0 then
        local tc=g:GetFirst()
        Duel.NegateRelatedChain(tc,RESET_TURN_SET)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetValue(RESET_TURN_SET)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e2)
        Duel.Destroy(tc,REASON_EFFECT)
    end
end

function s.setfilter(c,tp)
    return c:IsControler(1-tp) and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.setcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(Card.IsPreviousControler,1,nil,1-tp)
end

function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsSSetable() end
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    --Restriction
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
    
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsSSetable() and Duel.SSet(tp,c)>0 then
        --Banish it when it leaves the field
        local e1=Effect.CreateEffect(c)
        e1:SetDescription(3300)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
        e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
        e1:SetValue(LOCATION_REMOVED)
        e1:SetReset(RESET_EVENT|RESETS_REDIRECT)
        c:RegisterEffect(e1)
    end
end

function s.bancon(e)
    return e:GetHandler():GetFlagEffect(id)~=0
end

function s.splimit(e,c)
    return not c:IsSetCard(0x1735)
end
