--Dreary Cell
local s,id=GetID()
function s.initial_effect(c)
	--Counter trap activation
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_names={62400001}
function s.cfilter(c)
	return c:IsFaceup() and (c:IsCode(62400001) or (c:IsType(TYPE_FUSION) and c:ListsCode(62400001)))
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return (re:IsMonsterEffect() or re:IsHasType(EFFECT_TYPE_ACTIVATE)) 
		and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
		and re:GetActivateLocation()&(LOCATION_MZONE+LOCATION_SZONE)>0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local tc=re:GetHandler()
    if Duel.NegateActivation(ev) and tc:IsRelateToEffect(re) then
        local seq=tc:GetSequence()
        local loc=tc:GetLocation()
        local g=Group.FromCards(tc)
        if loc==LOCATION_MZONE then
            local g1=Duel.GetMatchingGroup(Card.IsDestructable,tp,0,LOCATION_MZONE,nil)
            local g2=Duel.GetMatchingGroup(Card.IsDestructable,tp,0,LOCATION_SZONE,nil)
            if seq>0 and g1:IsExists(Card.IsSequence,1,nil,seq-1) then
                g:AddCard(g1:Filter(Card.IsSequence,nil,seq-1):GetFirst())
            end
            if seq<4 and g1:IsExists(Card.IsSequence,1,nil,seq+1) then
                g:AddCard(g1:Filter(Card.IsSequence,nil,seq+1):GetFirst())
            end
            if g2:IsExists(Card.IsSequence,1,nil,seq) then
                g:AddCard(g2:Filter(Card.IsSequence,nil,seq):GetFirst())
            end
        end
        if loc==LOCATION_SZONE then
            local g1=Duel.GetMatchingGroup(Card.IsDestructable,tp,0,LOCATION_SZONE,nil)
            local g2=Duel.GetMatchingGroup(Card.IsDestructable,tp,0,LOCATION_MZONE,nil)
            if seq>0 and g1:IsExists(Card.IsSequence,1,nil,seq-1) then
                g:AddCard(g1:Filter(Card.IsSequence,nil,seq-1):GetFirst())
            end
            if seq<4 and g1:IsExists(Card.IsSequence,1,nil,seq+1) then
                g:AddCard(g1:Filter(Card.IsSequence,nil,seq+1):GetFirst())
            end
            if g2:IsExists(Card.IsSequence,1,nil,seq) then
                g:AddCard(g2:Filter(Card.IsSequence,nil,seq):GetFirst())
            end
        end
        Duel.Destroy(g,REASON_EFFECT)
    end
end
