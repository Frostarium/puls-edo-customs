--Star Signis Orange - Chrysanthemum
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon 1 "Star Signis" monster from GY or Hand (Ignition Version)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,{id,0})
    e1:SetCost(Cost.SelfDiscard)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    e1:SetCondition(s.normalcon)
    c:RegisterEffect(e1)
    
    --Special Summon 1 "Star Signis" monster from GY or Hand (Quick Version)
    local e6=e1:Clone()
    e6:SetType(EFFECT_TYPE_QUICK_O)
    e6:SetCode(EVENT_FREE_CHAIN)
    e6:SetHintTiming(0,TIMING_END_PHASE)
    e6:SetCondition(s.quickcon)
    c:RegisterEffect(e6)

    --Special Summon from hand (Ignition Version)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_HAND)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.target)
    e2:SetOperation(s.operation)
    e2:SetCondition(s.normalcon)
    c:RegisterEffect(e2)

    --Special Summon from hand (Quick Version)
    local e3=e2:Clone()
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetHintTiming(0,TIMING_END_PHASE)
    e3:SetCondition(s.quickcon)
    c:RegisterEffect(e3)

    --Return 1 Monster from GY to Deck, Special Summon this card from GY
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
    e4:SetCountLimit(1,{id,1})
    e4:SetTarget(s.target)
    e4:SetOperation(s.operation)
    c:RegisterEffect(e4)

    --Draw 2 cards discard 1
    local e5=Effect.CreateEffect(c)
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e5:SetCode(EVENT_CHAINING)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1,{id,2})
    e5:SetCondition(s.drcon)
    e5:SetCost(s.discost)
    e5:SetTarget(s.drtarg)
    e5:SetOperation(s.drop)
    c:RegisterEffect(e5)
end

-- Add new condition functions
function s.quickcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsPlayerAffectedByEffect(tp,78000000)
end

function s.normalcon(e,tp,eg,ep,ev,re,r,rp)
    return not Duel.IsPlayerAffectedByEffect(tp,78000000)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_GRAVE+LOCATION_HAND,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_HAND)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.filter),tp,LOCATION_GRAVE+LOCATION_HAND,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end
function s.filter(c,e,tp)
    return c:IsSetCard(0xbbb) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and s.tdfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) and
        Duel.SendtoDeck(tc,nil,2,REASON_EFFECT)
        and c:IsRelateToEffect(e) then
            Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
        end
        --Cannot Special Summon from the Extra Deck, except Xyz Monsters
        local e1=Effect.CreateEffect(c)
        e1:SetDescription(aux.Stringid(id,2))
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
        e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        e1:SetTargetRange(1,0)
        e1:SetTarget(function(_,c) return not c:IsType(TYPE_XYZ) and c:IsLocation(LOCATION_EXTRA) end)
        e1:SetReset(RESET_PHASE|PHASE_END)
        Duel.RegisterEffect(e1,tp)
        --Clock Lizard check
        aux.addTempLizardCheck(c,tp,function(_,c) return not c:IsOriginalType(TYPE_XYZ) end)
    end
function s.tdfilter(c)
    return c:IsMonster() and c:IsAbleToDeck() and not c:IsCode(id)
end
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
    return ep==1-tp and re:IsSpellTrapEffect() and re:GetHandler():IsRelateToEffect(re)
end
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,e:GetHandler()) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD,nil)
end
function s.drtarg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(2)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
    local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
    Duel.Draw(p,d,REASON_EFFECT)
end