--Armies of Noxus
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)
    --Destroy Nox monster to special summon Nox monster
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1)
    e1:SetRange(LOCATION_SZONE)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    --Draw when card is destroyed
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DESTROYED)
    e2:SetRange(LOCATION_SZONE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(2)
    e2:SetTarget(s.drawtg)
    e2:SetOperation(s.drawop)
    c:RegisterEffect(e2)
    --Special summon from GY to opponent's field
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetCountLimit(1,{id,1})
    e3:SetRange(LOCATION_SZONE)
    e3:SetCondition(s.spcon2)
    e3:SetTarget(s.sptg2)
    e3:SetOperation(s.spop2)
    c:RegisterEffect(e3)
end

function s.spfilter(c,tp)
    return c:IsSetCard(0x1735) and c:IsMonster() and c:IsControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.spfilter,1,nil,tp)
end

function s.desfilter(c)
    return c:IsSetCard(0x1735) and c:IsMonster() and c:IsFaceup()
end

function s.spfilter2(c,e,tp)
    return c:IsSetCard(0x1735) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.desfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.desfilter,tp,LOCATION_MZONE,0,1,nil)
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectTarget(tp,s.desfilter,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and Duel.Destroy(tc,REASON_EFFECT)>0 then
        if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local g=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
            if #g>0 then
                Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
            end
        end
    end
end

function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.drawop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Draw(tp,1,REASON_EFFECT)
end

function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)==0
end

function s.spfilter3(c,e,tp)
    return c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,1-tp)
end

function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and s.spfilter3(chkc,e,tp) end
    if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
        and Duel.IsExistingTarget(s.spfilter3,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,e,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(tp,s.spfilter3,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 then
        if Duel.SpecialSummon(tc,0,tp,1-tp,false,false,POS_FACEUP)>0 then
            --Negate effects
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
            e2:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e2)
        end
    end
end
