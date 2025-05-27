--Dark Blade + Pitch Dark
local s,id=GetID()
function s.initial_effect(c)
    --Fusion material
    c:EnableReviveLimit()
    Fusion.AddProcMix(c,true,true,11321183,s.ffilter)
    Fusion.AddContactProc(c,s.contactfil,s.contactop,false)
    --spsummon condition
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    e1:SetValue(aux.fuslimit)
    c:RegisterEffect(e1)
    
    --Special summon by banishing
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_SPSUMMON_PROC)
    e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e2:SetRange(LOCATION_HAND+LOCATION_DECK)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
    
    --Add card that mentions Dark Blade
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
    
    --ATK boost and direct attack for DARK monsters
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_UPDATE_ATTACK)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTargetRange(LOCATION_MZONE,0)
    e4:SetTarget(aux.TargetBoolFunction(Card.IsAttribute,ATTRIBUTE_DARK))
    e4:SetValue(500)
    c:RegisterEffect(e4)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_DIRECT_ATTACK)
    e5:SetRange(LOCATION_MZONE)
    e5:SetTargetRange(LOCATION_MZONE,0)
    e5:SetTarget(aux.TargetBoolFunction(Card.IsAttribute,ATTRIBUTE_DARK))
    c:RegisterEffect(e5)
    
    --Return and summon Dark Blade with union
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,2))
    e6:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
    e6:SetType(EFFECT_TYPE_QUICK_O)
    e6:SetCode(EVENT_FREE_CHAIN)
    e6:SetRange(LOCATION_MZONE)
    e6:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e6:SetCountLimit(1,{id,1})
    e6:SetCost(s.retcost)
    e6:SetTarget(s.rettg)
    e6:SetOperation(s.retop)
    c:RegisterEffect(e6)
end
s.listed_names={11321183}


function s.spfilter(c)
    return c:IsFaceup() and c:IsAbleToRemoveAsCost() and 
        (c:IsCode(11321183) or (c:IsRace(RACE_DRAGON) and c:IsAttribute(ATTRIBUTE_DARK)))
end

function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if ft<0 then return false end
    local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_MZONE,0,nil)
    return g:CheckSubGroup(s.spcheck,2,2,tp)
end

function s.spcheck(g,tp)
    return g:IsExists(Card.IsCode,1,nil,11321183) and 
        g:IsExists(function(c) return c:IsRace(RACE_DRAGON) and c:IsAttribute(ATTRIBUTE_DARK) end,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
    local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_MZONE,0,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local sg=g:SelectSubGroup(tp,s.spcheck,false,2,2,tp)
    if sg then
        sg:KeepAlive()
        e:SetLabelObject(sg)
        return true
    else return false end
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    Duel.Remove(g,POS_FACEUP,REASON_COST)
    g:DeleteGroup()
end

function s.thfilter(c)
    return c:ListsCode(11321183) and c:IsAbleToHand()
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
        Duel.ShuffleDeck(tp)
    end
end

function s.retcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToExtraAsCost() end
    Duel.SendtoDeck(e:GetHandler(),nil,SEQ_DECKTOP,REASON_COST)
end

function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsCode(11321183) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1
        and Duel.IsExistingTarget(Card.IsCode,tp,LOCATION_REMOVED,0,1,nil,11321183) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    Duel.SelectTarget(tp,Card.IsCode,tp,LOCATION_REMOVED,0,1,1,nil,11321183)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_REMOVED)
end

function s.unionfilter(c)
    return c:IsType(TYPE_UNION) and c:IsFaceup()
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
        if Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
            and Duel.IsExistingMatchingCard(s.unionfilter,tp,LOCATION_REMOVED,0,1,nil) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
            local ug=Duel.SelectMatchingCard(tp,s.unionfilter,tp,LOCATION_REMOVED,0,1,1,nil)
            if #ug>0 then
                Duel.Equip(tp,ug:GetFirst(),tc)
            end
        end
    end
end

function s.ffilter(c,fc,sumtype,tp)
    return c:IsRace(RACE_DRAGON,fc,sumtype,tp) and c:IsAttribute(ATTRIBUTE_DARK,fc,sumtype,tp)
end

function s.contactfil(tp)
    return Duel.GetMatchingGroup(Card.IsAbleToRemoveAsCost,tp,LOCATION_MZONE,0,nil)
end

function s.contactop(g)
    Duel.Remove(g,POS_FACEUP,REASON_COST|REASON_MATERIAL)
end