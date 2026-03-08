--Forsaken Cruel Ritual
local s,id=GetID()
function s.initial_effect(c)
    -- Effect 1: Ritual Summon 1 "Cruel" monster from the Deck (equal-level tribute)
    local e1=Ritual.CreateProc({
        handler=c,
        lvtype=RITPROC_EQUAL,
        filter=aux.FilterBoolFunction(Card.IsSetCard,0x67e),
        location=LOCATION_DECK,
        -- customoperation lets us run extra steps after the ritual summon
        customoperation=s.ritualop,
    })
    e1:SetCountLimit(1,id)
    c:RegisterEffect(e1)
end

s.listed_series={0x67e}
    -- Called by customoperation: handles the Ritual Summon and then applies the level reduction.
-- Parameters: mat (tribute group), e (effect), tp (turn player), ... standard op params, tc (monster being summoned)
function s.ritualop(mat,e,tp,eg,ep,ev,re,r,rp,tc)
    -- Perform the Ritual Summon manually (mirrors what Ritual.Operation does by default)
    tc:SetMaterial(mat)
    Duel.ReleaseRitualMaterial(mat)
    Duel.BreakEffect()
    Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
    tc:CompleteProcedure()

    -- Determine the Level of the just-summoned Ritual monster
    local summon_lv=tc:GetLevel()
    if summon_lv<=0 then return end

    -- Gather all face-up monsters on the field (both sides) and in both GYs,
    -- excluding the monster that was just summoned
    local tg=Duel.GetMatchingGroup(s.lvrkfilter,tp,
        LOCATION_MZONE+LOCATION_GRAVE,
        LOCATION_MZONE+LOCATION_GRAVE,tc)

    for c2 in tg:Iter() do
        -- Apply a CHANGE_LEVEL effect if the monster has a Level
        if c2:HasLevel() then
            local newlv=math.max(1, c2:GetLevel()-summon_lv)
            local ef=Effect.CreateEffect(e:GetHandler())
            ef:SetType(EFFECT_TYPE_SINGLE)
            ef:SetCode(EFFECT_CHANGE_LEVEL)
            ef:SetValue(newlv)
            ef:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END)
            c2:RegisterEffect(ef)
        end
        -- Apply a CHANGE_RANK effect if the monster has a Rank (Xyz monsters)
        if c2:GetRank()>0 then
            local newrk=math.max(1, c2:GetRank()-summon_lv)
            local ef=Effect.CreateEffect(e:GetHandler())
            ef:SetType(EFFECT_TYPE_SINGLE)
            ef:SetCode(EFFECT_CHANGE_RANK)
            ef:SetValue(newrk)
            ef:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END)
            c2:RegisterEffect(ef)
        end
    end
end
-- Filter: face-up monsters that have a Level or a Rank
function s.lvrkfilter(c)
    return c:IsType(TYPE_MONSTER) and c:IsFaceup() and (c:HasLevel() or c:GetRank()>0)
end