--Hyozanryu
local s,id=GetID()
function s.initial_effect(c)
    --Equip from banished
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_EQUIP)
    e1:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
    e1:SetCode(EVENT_REMOVE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetTarget(s.eqtg)
    e1:SetOperation(s.eqop)
    c:RegisterEffect(e1)
    
    --Destroy weaker monsters
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_EQUIP)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
    
    --ATK boost
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_EQUIP)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetValue(500)
    c:RegisterEffect(e3)
    
    --Destruction replacement
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_EQUIP)
    e4:SetCode(EFFECT_DESTROY_REPLACE)
    e4:SetTarget(s.reptg)
    e4:SetValue(s.repval)
    e4:SetOperation(s.repop)
    c:RegisterEffect(e4)
    
    --Equip limit
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_EQUIP_LIMIT)
    e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e5:SetValue(s.eqlimit)
    c:RegisterEffect(e5)
end
s.listed_names={11321183}
function s.eqfilter(c)
    return c:IsFaceup() and c:IsCode(11321183)
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.eqfilter(chkc) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
        and Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
    Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        Duel.Equip(tp,c,tc)
    end
end

function s.eqlimit(e,c)
    return c:IsCode(11321183)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local eq=c:GetEquipTarget()
    if chk==0 then return eq and eg:IsContains(eq) and not eq:IsReason(REASON_REPLACE) 
        and c:IsDestructable() and not c:IsStatus(STATUS_DESTROY_CONFIRMED) end
    return Duel.SelectEffectYesNo(tp,c,96)
end

function s.repval(e,c)
    return e:GetHandler():GetEquipTarget()
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Destroy(e:GetHandler(),REASON_EFFECT+REASON_REPLACE)
end

function s.descon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():GetEquipTarget()
end

function s.desfilter(c,atk)
    return c:IsFaceup() and c:IsAttackBelow(atk-1)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    local eq=e:GetHandler():GetEquipTarget()
    if chk==0 then return eq and Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_MZONE,1,nil,eq:GetAttack()) end
    local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil,eq:GetAttack())
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local eq=e:GetHandler():GetEquipTarget()
    if eq then
        local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil,eq:GetAttack())
        if #g>0 then
            Duel.Destroy(g,REASON_EFFECT)
        end
    end
end
