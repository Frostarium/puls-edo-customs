--Star Signis Skyfall
local s,id=GetID()
function s.initial_effect(c)
--activate
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_ACTIVATE)
e1:SetCode(EVENT_FREE_CHAIN)
c:RegisterEffect(e1)
--Atk up
local e2=Effect.CreateEffect(c)
e2:SetType(EFFECT_TYPE_FIELD)
e2:SetRange(LOCATION_SZONE)
e2:SetTargetRange(LOCATION_MZONE,0)
e2:SetCode(EFFECT_UPDATE_ATTACK)
e2:SetCondition(s.con)
e2:SetValue(300)
c:RegisterEffect(e2)
local e3=Effect.CreateEffect(c)
e3:SetType(EFFECT_TYPE_FIELD)
e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
e3:SetCode(EFFECT_CANNOT_ACTIVATE)
e3:SetRange(LOCATION_SZONE)
e3:SetTargetRange(0,1)
e3:SetCondition(s.actcon)   
e3:SetValue(s.actlimit)
c:RegisterEffect(e3)
-- Target 1 face-up monster on the field and 1 card in either graveyard
local e4=Effect.CreateEffect(c)
e4:SetCategory(CATEGORY_TODECK)
e4:SetType(EFFECT_TYPE_QUICK_O)
e4:SetCode(EVENT_FREE_CHAIN)
e4:SetRange(LOCATION_SZONE)
e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
e4:SetCountLimit(1)
e4:SetTarget(s.target)
e4:SetOperation(s.operation)
c:RegisterEffect(e4)
end
function s.con(e)
	local ph=Duel.GetCurrentPhase()
	return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end

function s.actcon(e)
local tc=Duel.GetAttacker()
local tp=e:GetHandlerPlayer()
return tc and tc:IsControler(tp)
end
function s.actlimit(e,re,tp)
    return re:IsActiveType(TYPE_MONSTER)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then 
        return false --Return false because we have two different target conditions
    end
    if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
        and Duel.IsExistingTarget(Card.IsAbleToDeck,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil) end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g1=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
    e:SetLabelObject(g1:GetFirst())
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g2=Duel.SelectTarget(tp,Card.IsAbleToDeck,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g2,1,0,0)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
    local tc1=e:GetLabelObject() --the monster target
    local tc2=g:GetFirst() --the GY target
    if tc2==tc1 then tc2=g:GetNext() end --ensure we get the correct GY target
    
    if not tc1:IsRelateToEffect(e) or not tc1:IsFaceup() 
        or not tc2:IsRelateToEffect(e) then return end
    
    if Duel.SendtoDeck(tc2,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 
        and tc2:IsLocation(LOCATION_DECK|LOCATION_EXTRA) then
        
        if tc2:GetOwner()==tp then
            --Make unaffected
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_IMMUNE_EFFECT)
            e1:SetValue(s.efilter)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc1:RegisterEffect(e1)
        else
            --Negate effects
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc1:RegisterEffect(e1)
            local e2=e1:Clone()
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            tc1:RegisterEffect(e2)
        end
    end
end

function s.efilter(e,te)
    if te:GetOwner()==e:GetOwner() then return false end
    return te:IsActivated()
end
