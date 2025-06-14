--Awakening of the Forgotten Universes
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    --GY effect
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCost(Cost.SelfBanish)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.gytg)
    e2:SetOperation(s.gyop)
    c:RegisterEffect(e2)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,e:GetHandler()) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD,e:GetHandler())
end

function s.thfilter(c)
    return c:IsSetCard(0x5bc) and c:IsAbleToHand()
end

function s.spfilter(c,e,tp)
    return c:IsType(TYPE_NORMAL) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) then
        Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
    end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local no_monsters=Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,2,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
    if no_monsters and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
        and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
        if #sg>0 then
            Duel.BreakEffect()
            Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end

function s.gfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_NORMAL) and c:IsSetCard(0x5bc)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.gfilter,tp,LOCATION_MZONE,0,1,nil) end
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local tc=Duel.SelectMatchingCard(tp,s.gfilter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
    if tc then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetDescription(aux.Stringid(id,3))
        e1:SetCategory(CATEGORY_TOHAND)
        e1:SetType(EFFECT_TYPE_IGNITION)
        e1:SetRange(LOCATION_MZONE)
        e1:SetCountLimit(1)
        e1:SetTarget(s.rth_tg)
        e1:SetOperation(s.rth_op)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
end

function s.rthfilter(c)
    return c:IsSetCard(0x5bc) and c:IsAbleToHand()
end

function s.rth_tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.rthfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.rth_op(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.rthfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end
