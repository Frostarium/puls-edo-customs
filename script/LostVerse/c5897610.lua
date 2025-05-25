--Soldier of a Lost Universe
local s,id=GetID()
function s.initial_effect(c)
    --Discard to activate one of the effects
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
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
    if chk==0 then return s.drawtg(e,tp,eg,ep,ev,re,r,rp,0) or s.granteffecttg(e,tp,eg,ep,ev,re,r,rp,0) end
    if s.drawtg(e,tp,eg,ep,ev,re,r,rp,0) and s.granteffecttg(e,tp,eg,ep,ev,re,r,rp,0) then
        local op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
        e:SetLabel(op)
    elseif s.drawtg(e,tp,eg,ep,ev,re,r,rp,0) then
        e:SetLabel(0)
    else
        e:SetLabel(1)
    end
    if e:GetLabel()==0 then
        s.drawtg(e,tp,eg,ep,ev,re,r,rp,1)
    else
        s.granteffecttg(e,tp,eg,ep,ev,re,r,rp,1)
    end
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    if e:GetLabel()==0 then
        s.drawop(e,tp,eg,ep,ev,re,r,rp)
    else
        s.granteffectop(e,tp,eg,ep,ev,re,r,rp)
    end
end

function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.spfilter(c,e,tp)
    return c:IsType(TYPE_NORMAL) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.drawop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
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
        e1:SetCategory(CATEGORY_DISABLE)
        e1:SetType(EFFECT_TYPE_QUICK_O)
        e1:SetCode(EVENT_FREE_CHAIN)
        e1:SetRange(LOCATION_MZONE)
        e1:SetCountLimit(1)
        e1:SetTarget(s.negtg)
        e1:SetOperation(s.negop)
        tc:RegisterEffect(e1)
    end
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsType,tp,0,LOCATION_MZONE,1,nil,TYPE_MONSTER) end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_MZONE)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
    local tc=Duel.SelectMatchingCard(tp,Card.IsType,tp,0,LOCATION_MZONE,1,1,nil,TYPE_MONSTER):GetFirst()
    if tc then
        --Negate effects
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e2)
        --Change ATK to 0
        local e3=Effect.CreateEffect(e:GetHandler())
        e3:SetType(EFFECT_TYPE_SINGLE)
        e3:SetCode(EFFECT_SET_ATTACK_FINAL)
        e3:SetValue(0)
        e3:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e3)
        local e4=Effect.CreateEffect(e:GetHandler())
        e4:SetType(EFFECT_TYPE_SINGLE)
        e4:SetCode(EFFECT_SET_DEFENSE_FINAL)
        e4:SetValue(0)
        e4:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e4)

        --Cannot be used as material
        local e5=Effect.CreateEffect(e:GetHandler())
        e5:SetType(EFFECT_TYPE_SINGLE)
        e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e5:SetCode(EFFECT_CANNOT_BE_MATERIAL)
        e5:SetValue(aux.cannotmatfilter(SUMMON_TYPE_FUSION,SUMMON_TYPE_SYNCHRO,SUMMON_TYPE_XYZ,SUMMON_TYPE_LINK))
        e5:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e5)
        --Cannot be tributed
        local e6=Effect.CreateEffect(e:GetHandler())
        e6:SetType(EFFECT_TYPE_SINGLE)
        e6:SetCode(EFFECT_UNRELEASABLE_SUM)
        e6:SetValue(1)
        e6:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e6)
        local e7=e5:Clone()
        e7:SetCode(EFFECT_UNRELEASABLE_NONSUM)
        tc:RegisterEffect(e7)
    end
end
