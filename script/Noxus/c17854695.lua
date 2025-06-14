--Ambessa
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon from hand/GY when a card is destroyed, then destroy column
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_DESTROYED)
    e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
    e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    --Negate and destroy when declaring attack
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_ATTACK_ANNOUNCE)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)
    
    --Damage/LP gain when cards are destroyed
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_DAMAGE+CATEGORY_RECOVER)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_DESTROYED)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.damcon)
    e3:SetOperation(s.damop)
    c:RegisterEffect(e3)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(Card.IsPreviousControler,1,nil,tp) and eg:IsExists(Card.IsPreviousLocation,1,nil,LOCATION_ONFIELD)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) and ((c:IsLocation(LOCATION_GRAVE) and not eg:IsContains(c)) 
		or (c:IsLocation(LOCATION_HAND))) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
    end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
        --Destroy cards in same column
        local seq=c:GetSequence()
        local g=Group.CreateGroup()
        for p=0,1 do
            local tc=Duel.GetFieldCard(p,LOCATION_MZONE,seq)
            if tc and tc~=c then g:AddCard(tc) end
            local tc2=Duel.GetFieldCard(p,LOCATION_SZONE,seq)
            if tc2 then g:AddCard(tc2) end
        end
        if #g>0 then
            Duel.Destroy(g,REASON_EFFECT)
        end
    end
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() and chkc:IsNegatableCard() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsNegatableCard,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
    local g=Duel.SelectTarget(tp,Card.IsNegatableCard,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,g,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        Duel.NegateActivation(tc)
        Duel.Destroy(tc,REASON_EFFECT)
    end
end

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(Card.IsPreviousLocation,1,nil,LOCATION_ONFIELD)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
    local ct=eg:FilterCount(Card.IsPreviousLocation,nil,LOCATION_ONFIELD)
    if ct>0 then
        Duel.Damage(1-tp,ct*1000,REASON_EFFECT)
        Duel.Recover(tp,ct*500,REASON_EFFECT)
    end
end
