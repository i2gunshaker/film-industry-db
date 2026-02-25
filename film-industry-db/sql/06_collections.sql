--------------------Collections--------------------------------
--1
/*selects all movie titles for a given genre (Drama), collects them into a PL/SQL table, and prints:
the genre name
how many movies were found
the list of titles in order (newest first).
*/
declare
    type t_title_tab is table of movie.title%type;
    v_titles t_title_tab;

    v_genre_name genre.genrename%type := 'Drama';
begin
    select m.title
    bulk collect into v_titles
    from movie m
    join movie_genre mg on mg.movieid = m.movieid
    join genre g on g.genreid = mg.genreid
    where g.genrename = v_genre_name
    order by m.releasedate desc;

    dbms_output.put_line('Genre: ' || v_genre_name);
    dbms_output.put_line('Movies found: ' || v_titles.count);

    if v_titles.count > 0 then
        for i in v_titles.first .. v_titles.last loop
            dbms_output.put_line(i || '. ' || v_titles(i));
        end loop;
    end if;
end;
/

--2 It builds an in-memory list of all actors and how many movies they acted in, then prints only those who appeared in 10 or more movies.

declare
    type t_actor_stat is record (
        actor_id    actor.actorid%type,
        full_name   varchar2(201),
        movie_count pls_integer
    );

    type t_actor_stat_tab is table of t_actor_stat index by pls_integer;

    v_stats t_actor_stat_tab;
    i       pls_integer := 0;
begin
    for r in (
        select a.actorid,
               a.firstname || ' ' || a.lastname as full_name,
               count(distinct mc.movieid) as movie_count
        from actor a
        join movie_cast mc on mc.actorid = a.actorid
        group by a.actorid, a.firstname, a.lastname
    ) loop
        i := i + 1;
        v_stats(i).actor_id    := r.actorid;
        v_stats(i).full_name   := r.full_name;
        v_stats(i).movie_count := r.movie_count;
    end loop;

    dbms_output.put_line('Busy actors (10+ movies):');

    i := v_stats.first;
    while i is not null loop
        if v_stats(i).movie_count >= 10 then
            dbms_output.put_line(
                v_stats(i).full_name || ' (ID=' || v_stats(i).actor_id ||
                ') -> ' || v_stats(i).movie_count || ' movies'
            );
        end if;

        i := v_stats.next(i);
    end loop;
end;
/