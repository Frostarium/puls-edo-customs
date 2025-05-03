--Flagship Palamecia
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    
    --Cannot activate cards/effects when Link Summoning PSICOM
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetRange(LOCATION_FZONE)
    e2:SetOperation(s.sumsuc)
    c:RegisterEffect(e2)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_CANNOT_ACTIVATE)
    e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e3:SetRange(LOCATION_FZONE)
    e3:SetTargetRange(0,1)
    e3:SetValue(1)
    e3:SetCondition(s.actcon)
    c:RegisterEffect(e3)
    
    --Shuffle and Draw effect
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_FZONE)
    e4:SetCountLimit(1,id)
    e4:SetTarget(s.tdtg)
    e4:SetOperation(s.tdop)
    c:RegisterEffect(e4)
end

--Summon Success check
function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
    local tc=eg:GetFirst()
    for tc in aux.Next(eg) do
        if tc:IsType(TYPE_LINK) and tc:IsSetCard(0xfff) and tc:IsSummonType(SUMMON_TYPE_LINK) then
            Duel.SetChainLimitTillChainEnd(function(e,rp,tp) return tp==rp end)
        end
    end
end

--Activation limitation
function s.actcon(e)
    local ph=Duel.GetCurrentPhase()
    return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end

--Check for Link-2 or higher PSICOM
function s.cfilter(c,tp)
    return c:IsType(TYPE_LINK) and c:IsSetCard(0xfff) and c:IsLinkAbove(2)
        and c:IsSummonType(SUMMON_TYPE_LINK) and c:IsSummonPlayer(tp)
end

function s.tdfilter(c)
    return c:IsSetCard(0xfff) and c:IsMonster() and (c:IsAbleToDeck() or c:IsAbleToExtra())
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,nil)
        and Duel.IsPlayerCanDraw(tp,1) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,3,nil)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g,3,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)
    if #g==3 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
        Duel.ShuffleDeck(tp)
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end
