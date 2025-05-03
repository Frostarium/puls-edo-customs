--The Ruination
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    
    --Grant effect to "Ruined" monsters
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_ADJUST)
    e2:SetRange(LOCATION_FZONE)
    e2:SetOperation(s.effop)
    c:RegisterEffect(e2)
    
    --Draw cards
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_DRAW)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_PHASE+PHASE_END)
    e3:SetRange(LOCATION_FZONE)
    e3:SetCountLimit(1,{id,2})
    e3:SetCondition(s.drcon)
    e3:SetTarget(s.drtg)
    e3:SetOperation(s.drop)
    c:RegisterEffect(e3)
     --Protection
     local e4=Effect.CreateEffect(c)
     e4:SetType(EFFECT_TYPE_FIELD)
     e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
     e4:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
     e4:SetRange(LOCATION_MZONE)
     e4:SetTargetRange(LOCATION_MZONE,0)
     e4:SetTarget(s.tgtarget)
     e4:SetValue(aux.tgoval)
     c:RegisterEffect(e4)
end

-- Add a global variable to track affected monsters
s.affected_cards = {}

function s.effop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,0x35b),tp,LOCATION_MZONE,0,nil)
    for tc in aux.Next(g) do
        if not s.affected_cards[tc] then
            --Steal destroyed monster
            local e1=Effect.CreateEffect(c)
            e1:SetDescription(aux.Stringid(id,0))
            e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
            e1:SetCode(EVENT_BATTLE_DESTROYING)
            e1:SetProperty(EFFECT_FLAG_DELAY)
            e1:SetCountLimit(1)
            e1:SetCondition(aux.bdocon)
            e1:SetTarget(s.sptg)
            e1:SetOperation(s.spop)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e1)
            tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
            s.affected_cards[tc] = true
        end
    end
end

--Target function for stealing
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local bc=e:GetHandler():GetBattleTarget()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and bc:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    bc:CreateEffectRelation(e)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,bc,1,0,0)
end

--Operation for stealing and modifying
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local bc=e:GetHandler():GetBattleTarget()
    if bc:IsRelateToEffect(e) and Duel.SpecialSummon(bc,0,tp,tp,false,false,POS_FACEUP)~=0 then
        --Treat as "Ruined"
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_ADD_SETCODE)
        e1:SetValue(0x35b)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        bc:RegisterEffect(e1)
        --Banish during End Phase
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e2:SetRange(LOCATION_MZONE)
        e2:SetCode(EVENT_PHASE+PHASE_END)
        e2:SetOperation(s.banop)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        e2:SetCountLimit(1)
        bc:RegisterEffect(e2)
    end
end

--Banish operation
function s.banop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT)
end

--Draw cards target
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local ct=Duel.GetMatchingGroupCount(aux.FaceupFilter(Card.IsSetCard,0x35b),tp,LOCATION_MZONE,0,nil)
    if ct>3 then ct=3 end
    if chk==0 then return ct>0 and Duel.IsPlayerCanDraw(tp,ct) end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(ct)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,ct)
end

--Draw cards operation
function s.drop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
    local ct=Duel.GetMatchingGroupCount(aux.FaceupFilter(Card.IsSetCard,0x35b),tp,LOCATION_MZONE,0,nil)
    if ct>2 then ct=2 end
    if ct>0 then
        Duel.Draw(p,ct,REASON_EFFECT)
    end
end

--Draw condition
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()==tp
end
function s.tgtarget(e,c)
    return c:IsFaceup() and c:IsSetCard(0x35b)
end
